//
//  RequestMode.swift
//  BrainRush
//
//  Created by Admin on 04/11/25.
//

import Foundation

enum RequestMode: String {
    case get = "GET"
    case post = "POST"
}

typealias ErrorCallBack = (String) -> Void

class ApiHelper {
    static let shared = ApiHelper()
    private init() { }
    
    func callAPI(url: String, method: RequestMode, headers: [String: String]? = nil, body: [String: Any]? = nil, successBlock: @escaping (Data) -> Void, failureBlock: @escaping ErrorCallBack){
        guard let apiUrl = URL(string: url) else {
            debugPrint("Can't find valid url")
            failureBlock("unknownError")
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = method.rawValue
        if let headers {
            request.allHTTPHeaderFields = headers
            debugPrint("Header: \(headers)")
        }
        if let body {
            debugPrint("Request: \(body)")
            let data = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = data
        }
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let data {
                successBlock(data)
            } else {
                failureBlock(error?.localizedDescription ?? "unknownError")
            }
        }).resume()
    }
}
