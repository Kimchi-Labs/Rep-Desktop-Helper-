//
//  GlobalHelpers.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/11/26.
//
import Foundation

/* If response status == pending: wait 1-2 seconds and retry
   If response contains desktop_access_token: store token and stop polling
   If expired/used/error: stop and show retry */


public final class AuthenticatePairing {
    public static func desktopAuthPoller() async throws -> String {
        
        let supabasePublicAnon: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94Z3Vtd3F4bmdocWNjYXp6cXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MTE0MjQsImV4cCI6MjA2Mjk4NzQyNH0.gt_S5p_sGgAEN1fJSPYIKEpDMMvo3PNx-pnhlC_2fKQ"
        
        var urlRequest: URLRequest = URLRequest(url: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/rep_desktop_pairing")!)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue(supabasePublicAnon, forHTTPHeaderField: "apikey")
        urlRequest.setValue("Bearer \(supabasePublicAnon)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let resp = response as? HTTPURLResponse, resp.statusCode == 200 else { throw ErrorDesc.urlResponseError }
        
        let decoder = JSONDecoder()
        let decodeResponse = try decoder.decode(DesktopPairing.self, from: data)
        
        let userId: String = decodeResponse.user_id ?? "user id empty"
        let desktopAccessToken: String = decodeResponse.desktop_access_token ?? "empty token"
        
        print("TOKEN: \(desktopAccessToken) | USER ID: \(userId)")
        return desktopAccessToken
    }
}
