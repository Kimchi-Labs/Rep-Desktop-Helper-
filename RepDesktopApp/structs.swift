//
//  structs.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/4/26.
//

public struct AudioSession: Decodable {             ///for audio transcription
    let session: SessionData
    
    public struct SessionData: Decodable {
        let value: String
        let expires_at: Int
        let session: SessionTypes
        
        public struct SessionTypes: Decodable {
            let type: String
            let id: String
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

public struct DesktopPairing: Decodable {
    let desktop_access_token: String?
    let user_id: String?
}


    /* {
     "status": "pending"
   } */
    
