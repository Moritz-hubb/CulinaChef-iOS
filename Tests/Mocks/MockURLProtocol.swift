import Foundation

/// Mock URLProtocol for testing network requests without actual network calls
class MockURLProtocol: URLProtocol {
    
    // MARK: - Static Configuration
    
    /// Handler for custom request/response behavior
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
    
    /// Reset mock state
    static func reset() {
        requestHandler = nil
    }
    
    // MARK: - URLProtocol Override
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true  // Handle all requests
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            // No handler configured - fail with error
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        do {
            let (response, data) = try handler(request)
            
            // Send response
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            // Send data if present
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            // Finish loading
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            // Send error
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // Nothing to stop in mock
    }
}

// MARK: - Helper Extensions

extension MockURLProtocol {
    
    /// Configure mock to return success response with JSON data
    static func mockResponse(statusCode: Int = 200, data: Data? = nil, headers: [String: String]? = nil) {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            return (response, data)
        }
    }
    
    /// Configure mock to return JSON response
    static func mockJSONResponse<T: Encodable>(_ object: T, statusCode: Int = 200) throws {
        let data = try JSONEncoder().encode(object)
        mockResponse(statusCode: statusCode, data: data, headers: ["Content-Type": "application/json"])
    }
    
    /// Configure mock to return error
    static func mockError(_ error: Error) {
        requestHandler = { _ in
            throw error
        }
    }
    
    /// Configure mock with custom validation and response
    static func mockWithValidation(
        validateRequest: @escaping (URLRequest) -> Bool,
        response: @escaping (URLRequest) -> (HTTPURLResponse, Data?)
    ) {
        requestHandler = { request in
            guard validateRequest(request) else {
                throw URLError(.badURL)
            }
            return response(request)
        }
    }
}

// MARK: - URLSession Extension for Testing

extension URLSession {
    /// Create URLSession configured with MockURLProtocol for testing
    static var mock: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
