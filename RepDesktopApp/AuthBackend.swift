import Foundation
import AuthenticationServices
import SwiftUI
import Supabase
import CryptoKit
import AppKit
import Combine


public final class AuthViewController: NSViewController {
    private let appleSignIn = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    private let backend = AuthBackend()

    private var currentNonce: String?

    public override func loadView() {
        view = NSView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(appleSignIn)
        appleSignIn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            appleSignIn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appleSignIn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            appleSignIn.heightAnchor.constraint(equalToConstant: 44),
            appleSignIn.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])

        appleSignIn.target = self
        appleSignIn.action = #selector(handleAppleSignInTapped)
    }

    @objc public func handleAppleSignInTapped() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()

        let nonce = randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension AuthViewController: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        backend.handleSuccessfulLogin(authorization, nonce: currentNonce)
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        backend.handleLoginError(with: error)
    }
}

extension AuthViewController: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? NSApplication.shared.keyWindow ?? NSWindow()
    }
}

public final class AuthBackend: ObservableObject {
    @Published public var isSignedIn: Bool = false
    
    public func loadSession() async {
        do {
            _ = try await supabaseDBClient.auth.session
            isSignedIn = true
        } catch {
            isSignedIn = false
        }
    }
    
    public func handleSuccessfulLogin(_ authorization: ASAuthorization, nonce: String?) {
        guard let userCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        print("User ID:", userCredential.user)

        if let tokenData = userCredential.identityToken,
           let tokenString = String(data: tokenData, encoding: .utf8) {
            Task {
                do {
                    let session = try await supabaseDBClient.auth.signInWithIdToken(credentials: OpenIDConnectCredentials(provider: .apple, idToken: tokenString, nonce: nonce))
                    
                    await MainActor.run {
                        self.isSignedIn = true
                    }

                    print("token exchange successful", session)
                } catch {
                    print("failed to exchange tokens with supabase", ErrorDesc.authTokenError, error)
                }
            }
        }
    }

    public func handleLoginError(with error: Error) {
        print("Could not authenticate: \(error.localizedDescription)")
    }
}

public struct AuthControllerRepresentable: NSViewControllerRepresentable {
    public func makeNSViewController(context: Context) -> AuthViewController {
        AuthViewController()
    }

    public func updateNSViewController(_ nsViewController: AuthViewController, context: Context) {}
}

public func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)

    return hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
}

public func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)

    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""

    var remainingLength = length

    while remainingLength > 0 {
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)

        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
        }
    }

    return result
}
