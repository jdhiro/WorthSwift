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

/// Standard fetch function.
func fetch<T: Encodable, R: Decodable>(
    _ path: String,
    queryItems: [URLQueryItem] = [],
    body: T?,
    method: HTTPMethods = .get) async throws -> R {
    
    var components = URLComponents()
    components.scheme = Constants.httpScheme
    components.host = Constants.httpHost
    components.port = Constants.httpPort
    components.path = path
    components.queryItems = queryItems

        
    var request = URLRequest(url: components.url!)
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
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
    let decodedData = try decoder.decode(R.self, from: data)
    return decodedData
}

/// Fetch overload to deal with the case of a missing generic body type.
func fetch<R: Decodable>(_ path: String, queryItems: [URLQueryItem] = [], method: HTTPMethods = .get) async throws -> R {
    return try await fetch(path, queryItems: queryItems, body: EmptyBody(), method: method)
}

func fetch(_ path: String, method: HTTPMethods = .get) async throws -> String {
    let url = URL(string: Constants.baseURL + path)!
        
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if (AppVars.token != nil) {
        request.setValue("Bearer " + AppVars.token!, forHTTPHeaderField: "Authorization")
    }
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let dataString = String(data: data, encoding: String.Encoding.utf8)
    return dataString!
}
