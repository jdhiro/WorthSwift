//
//  Network.swift
//  WorthSwift
//
//  Created by Jason Farnsworth on 7/10/21.
//

import Foundation


/// Add JSONDecoder.DateDecodingStrategy.iso8601withFractionalSeconds to deal with the fact that our service supports fractional seconds.cu
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

func fetch<T: Encodable, R: Decodable>(_ path: String, body: T?, method: HTTPMethods = .get) async throws -> R {
    let escapedPath = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let fullUrl: String = Constants.baseURL + escapedPath
    print("xxx", fullUrl)
    let url = URL(string: fullUrl)!
    
    var components = URLComponents()
    components.scheme = "https"
    components.host = Constants.baseURL
        
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if body != nil {
        // Process the body, and add it to the request.
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

func fetch<R: Decodable>(_ path: String, method: HTTPMethods = .get) async throws -> R {
    /// This is a workaround for the fact that Swift doesn't seem to support optional generics in its method calls. You have to create an optional
    /// type to call nil on.
    /// https://forums.swift.org/t/generic-function-that-requires-the-generic-type-to-be-non-optional/30936
    let fakeNil: Int? = nil
    return try await fetch(path, body: fakeNil, method: method)
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
