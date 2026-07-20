//
//  Error.Desc.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/4/26.
//
import Foundation


enum ErrorDesc: LocalizedError {
    case authTokenError
    case encodeError
    case decodeError
    case callsiteError
    case nilValue
    case serverError
    case urlResponseError
    case webSocketError
    case extractError
    case floatError
    case configError
    case sessionError
    case audioError
    case permissionsError
}

enum ErrorDefinition: Error {
    case emptyContent
}

public enum SupabaseError: LocalizedError {
    case upsertError
    case nilDataError
}



public typealias OpenAIStreamMeta = StreamEvent

public struct StreamEvent: Decodable {
    public let type: String
    public let delta: String?
    public let response: StreamResponse?
    
    public struct StreamResponse: Decodable {
        public let id: String
        public let status: String
        public let model: String
    }
}
