//
//  CreditsManager.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 9/6/26.
//
/* shared manager for payment and billing check related functions */
import Foundation
import Supabase


@MainActor
final class CreditsManager {
    private init() {}
    
    let audioManager = AudioTranscriptionManager.shared
    static let shared = CreditsManager()
    
    var task: Task<Void, Never>?
    
    
    func refreshUserCredits() {
        if audioManager.isMoreCreditsNeeded {
            guard task == nil else { return }
            
            task = Task {
                defer { task = nil }
                
                do {
                    while !Task.isCancelled {
                        let session = try await supabaseDBClient.auth.session
                        
                        let userBucket: BillingBucketCredits = try await supabaseDBClient.from("usage_buckets").select("""
                                                                                                       allowance,
                                                                                                       consumed:consumed_units,
                                                                                                       reserved:reserved_units
""").eq("user_id", value: session.user.id.uuidString).order("period_start", ascending: false).limit(1).single().execute().value
                        
                        applyCreditBucket(userBucket)
                        if !audioManager.isMoreCreditsNeeded { return }
                        try? await Task.sleep(for: .seconds(30))
                    }
                    
                } catch {
                    print("failed to run task loop in credits manager", ErrorDesc.taskError, error)
                }
            }
        }
    }

    
    func applyCreditBucket(_ bucket: BillingBucketCredits) {
        audioManager.isMoreCreditsNeeded = !bucket.hasAvailableCredits
    }

    func applyCreditResponse(statusCode: Int) throws {
        if statusCode == 402 {
            audioManager.isMoreCreditsNeeded = true
            refreshUserCredits()
            throw PaymentStoreError.insufficientTokens
        }

        guard (200...299).contains(statusCode) else { throw ErrorDesc.urlResponseError }
        audioManager.isMoreCreditsNeeded = false
    }
        
    
    func sendAudioBillingAction(_ action: String, body: [String: Any]) async throws {
        let url: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!
        let session = try await supabaseDBClient.auth.session
        guard !session.isExpired else { throw ErrorDesc.sessionError }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(action, forHTTPHeaderField: "x-rep-action")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            print("Audio billing action \(action) failed (\(httpResponse.statusCode)): \(responseBody)")
            throw ErrorDesc.urlResponseError
        }
    }
}
