//
//  Network.swift
//  WorthSwift
//
//  Created by Jason Farnsworth on 7/10/21.
//

import Foundation


/// Add JSONDecoder.DateDecodingStrategy.iso8601withFractionalSeconds to deal with the fact that our service supports fractional seconds.
/// Ideally in the future the service should switch to seconds or offer an option. There is a lot of odd code here in the app to work around it.
/// https://gist.github.com/Ikloo/e0011c99665dff0dd8c4d116150f9129
extension Formatter {
    static let iso8601: (regular: ISO8601DateFormatter, withFractionalSeconds: DateFormatter) = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return (ISO8601DateFormatter(), formatter)
    }()
}

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = Formatter.iso8601.withFractionalSeconds.date(from: string) {
            return date
        } else if let date = Formatter.iso8601.regular.date(from: string) {
            return date
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: " + string)
        }
    }
}

extension JSONEncoder.DateEncodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        var container = $1.singleValueContainer()
        try container.encode(Formatter.iso8601.withFractionalSeconds.string(from: $0))
    }
}

enum HTTPMethods: String {
    case get, head, post, put, delete, connect, options, trace, patch
}

/// Because we cannot pass an optional generic in a method signature, we have to "invent" a fake empty one and pass it along when there is no body. This is also why we have an overloaded method signature.
private struct EmptyBody: Codable { }

private struct SignInRequestBody: Codable {
    let username: String
    let password: String
}

private struct SignInResponseBody: Codable {
    let accessToken: String?
    let refreshToken: String?
}

private struct RefreshRequestBody: Codable {
    let refreshToken: String
}

private struct RefreshResponseBody: Codable {
    let accessToken: String?
    let refreshToken: String?
}

struct AuthTokens {
    let accessToken: String
    let refreshToken: String
}

enum AuthError: Error {
    case invalidResponse
    case missingToken
}

private func makeURLComponents(path: String, queryItems: [URLQueryItem]) -> URLComponents {
    var components = URLComponents()
    components.scheme = Constants.httpScheme
    components.host = Constants.httpHost
    if let port = Constants.httpPort {
        components.port = port
    }
    let normalizedPath = path.hasPrefix("/") ? path : "/" + path
    components.path = Constants.apiBasePath + normalizedPath
    if !queryItems.isEmpty {
        components.queryItems = queryItems
    }
    return components
}

func signIn(username: String, password: String) async throws -> AuthTokens {
    let body = SignInRequestBody(username: username.lowercased(), password: password)
    let (data, response) = try await fetchRaw("/auth/sign-in", body: body, method: .post, allowRefresh: false)
    if !(200...299).contains(response.statusCode) {
        throw AuthError.invalidResponse
    }
    if let body = try? JSONDecoder().decode(SignInResponseBody.self, from: data),
       let accessToken = body.accessToken,
       let refreshToken = body.refreshToken {
        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
    throw AuthError.missingToken
}

private func refreshSession() async throws -> Bool {
    guard let refreshToken = AppVars.refreshToken else {
        return false
    }

    let body = RefreshRequestBody(refreshToken: refreshToken)
    let (data, response) = try await fetchRaw("/auth/refresh", body: body, method: .post, allowRefresh: false)
    if !(200...299).contains(response.statusCode) {
        return false
    }

    if let decoded = try? JSONDecoder().decode(RefreshResponseBody.self, from: data),
       let accessToken = decoded.accessToken,
       let newRefreshToken = decoded.refreshToken {
        AppVars.token = accessToken
        AppVars.refreshToken = newRefreshToken
        return true
    }

    return false
}

func fetchRaw<T: Encodable>(
    _ path: String,
    queryItems: [URLQueryItem] = [],
    body: T?,
    method: HTTPMethods = .get,
    allowRefresh: Bool = true) async throws -> (Data, HTTPURLResponse) {
    
    let components = makeURLComponents(path: path, queryItems: queryItems)
    guard let url = components.url else {
        throw URLError(.badURL)
    }
        
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
    if body is EmptyBody {
        // Do nothing.
    } else {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedBody = try encoder.encode(body)
        request.httpBody = encodedBody
    }
        
    if (AppVars.token != nil) {
        request.setValue("Bearer " + AppVars.token!, forHTTPHeaderField: "Authorization")
    }
    
#if DEBUG
    print("REQUEST", request.httpMethod ?? "", request.url?.absoluteString ?? "")
    print("AUTH", request.value(forHTTPHeaderField: "Authorization") ?? "none")
#endif

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

#if DEBUG
    print("STATUS", httpResponse.statusCode)
    print("HEADERS", httpResponse.allHeaderFields)
    print("BODY", String(data: data, encoding: .utf8) ?? "<non-utf8>")
#endif
    if httpResponse.statusCode == 401 && allowRefresh {
        if try await refreshSession() {
            return try await fetchRaw(path, queryItems: queryItems, body: body, method: method, allowRefresh: false)
        }
    }

    return (data, httpResponse)
}

/// Standard fetch function.
func fetch<T: Encodable, R: Decodable>(
    _ path: String,
    queryItems: [URLQueryItem] = [],
    body: T?,
    method: HTTPMethods = .get) async throws -> R {

    let (data, _) = try await fetchRaw(path, queryItems: queryItems, body: body, method: method)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    // TODO: Catch and handle this try block.
    let decodedData = try decoder.decode(R.self, from: data)
    return decodedData
}

/// Fetch overload to deal with the case of a missing generic body type.
func fetch<R: Decodable>(_ path: String, queryItems: [URLQueryItem] = [], method: HTTPMethods = .get) async throws -> R {
    return try await fetch(path, queryItems: queryItems, body: EmptyBody(), method: method)
}
