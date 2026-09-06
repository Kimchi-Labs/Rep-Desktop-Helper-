//
//  structs.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/4/26.
//
import Foundation


public struct AudioSession: Decodable {             ///for audio transcription
    public let session: SessionData
    
    public struct SessionData: Decodable {
        public let value: String
        public let expires_at: Int
        public let session: SessionTypes
        
        public struct SessionTypes: Decodable {
            public let type: String
            public let id: String
        }
    }
}

public struct TranscriptionStream: Decodable {
    let type: String
    let item_id: String?
    let content_index: Int?
    let delta: String?
    let transcript: String?
    
}

struct BillingBucketCredits: Decodable, Sendable {
    let allowance: Decimal
    let consumed: Decimal
    let reserved: Decimal

    var remainingCredits: Decimal {
        max(allowance - consumed - reserved, 0)
    }

    var hasAvailableCredits: Bool {
        remainingCredits > 0
    }
}
