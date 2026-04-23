import XCTest
@testable import TodoApp

// MARK: - Mock Auth Services

final class StubAuthService: AuthService {
    var stubToken: String?
    var stubUser: User?

    init(stubToken: String? = nil, stubUser: User? = nil) {
        self.stubToken = stubToken
        self.stubUser = stubUser
    }

    func login(email: String, password: String) async throws {}
    func logout() { stubToken = nil; stubUser = nil }
    var token: String? { stubToken }
    var currentUser: User? { stubUser }
}

final class AlwaysNetworkErrorAuthService: AuthService {
    func login(email: String, password: String) async throws {
        throw AuthError.network("timeout")
    }
    func logout() {}
    var currentUser: User? { nil }
    var token: String? { nil }
}

final class AlwaysSucceedAuthService: AuthService {
    func login(email: String, password: String) async throws {}
    func logout() {}
    var currentUser: User? { nil }
    var token: String? { nil }
}

final class AlwaysFailAuthService: AuthService {
    func login(email: String, password: String) async throws {
        throw AuthError.invalidCredentials
    }
    func logout() {}
    var currentUser: User? { nil }
    var token: String? { nil }
}

final class SlowAuthService: AuthService {
    var didStart = false
    var didFinish = false
    func login(email: String, password: String) async throws {
        didStart = true
        didFinish = true
    }
    func logout() {}
    var currentUser: User? { nil }
    var token: String? { nil }
}

// MARK: - LoginViewModelTests

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: isLoginEnabled

    func test_isLoginEnabled_bothEmpty_returnsFalse() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = ""
        vm.password = ""
        XCTAssertFalse(vm.isLoginEnabled)
    }

    func test_isLoginEnabled_emailOnlyFilled_returnsFalse() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "test@example.com"
        vm.password = ""
        XCTAssertFalse(vm.isLoginEnabled)
    }

    func test_isLoginEnabled_passwordOnlyFilled_returnsFalse() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = ""
        vm.password = "secret"
        XCTAssertFalse(vm.isLoginEnabled)
    }

    func test_isLoginEnabled_bothFilled_returnsTrue() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "test@example.com"
        vm.password = "secret"
        XCTAssertTrue(vm.isLoginEnabled)
    }

    func test_isLoginEnabled_whitespaceEmail_returnsFalse() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "   "
        vm.password = "secret"
        XCTAssertFalse(vm.isLoginEnabled)
    }

    // MARK: Email Validation

    func test_emailValidation_validEmail_noError() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "user@example.com"
        XCTAssertFalse(vm.isEmailFormatInvalid)
    }

    func test_emailValidation_missingAt_isInvalid() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "userexample.com"
        XCTAssertTrue(vm.isEmailFormatInvalid)
    }

    func test_emailValidation_missingDomain_isInvalid() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "user@"
        XCTAssertTrue(vm.isEmailFormatInvalid)
    }

    func test_emailValidation_emptyString_noError() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = ""
        XCTAssertFalse(vm.isEmailFormatInvalid)
    }

    func test_emailValidation_withSubdomain_isValid() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "user@mail.example.co.uk"
        XCTAssertFalse(vm.isEmailFormatInvalid)
    }

    // MARK: Login Success

    func test_login_validCredentials_returnsTrue() async {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "user@example.com"
        vm.password = "password"
        let result = await vm.login()
        XCTAssertTrue(result)
        XCTAssertNil(vm.errorMessage)
    }

    func test_login_success_isLoadingFalseAfterwards() async {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "user@example.com"
        vm.password = "password"
        _ = await vm.login()
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: Login Failure

    func test_login_invalidCredentials_returnsFalse() async {
        let vm = LoginViewModel(authService: AlwaysFailAuthService())
        vm.email = "user@example.com"
        vm.password = "wrong"
        let result = await vm.login()
        XCTAssertFalse(result)
    }

    func test_login_invalidCredentials_setsErrorMessage() async {
        let vm = LoginViewModel(authService: AlwaysFailAuthService())
        vm.email = "user@example.com"
        vm.password = "wrong"
        _ = await vm.login()
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_login_invalidEmailFormat_setsErrorAndReturnsFalse() async {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        vm.email = "notanemail"
        vm.password = "password"
        let result = await vm.login()
        XCTAssertFalse(result)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: Loading State

    func test_login_isLoadingFalseAfterSuccess() async {
        let service = SlowAuthService()
        let vm = LoginViewModel(authService: service)
        vm.email = "user@example.com"
        vm.password = "password"
        _ = await vm.login()
        XCTAssertFalse(vm.isLoading)
        XCTAssertTrue(service.didFinish)
    }

    func test_login_isLoadingFalseAfterFailure() async {
        let vm = LoginViewModel(authService: AlwaysFailAuthService())
        vm.email = "user@example.com"
        vm.password = "wrong"
        _ = await vm.login()
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: Forgot Password

    func test_forgotPassword_setsAlertFlag() {
        let vm = LoginViewModel(authService: AlwaysSucceedAuthService())
        XCTAssertFalse(vm.showForgotPasswordAlert)
        vm.forgotPassword()
        XCTAssertTrue(vm.showForgotPasswordAlert)
    }

    // MARK: Network Error

    func test_login_networkError_setsErrorMessage() async {
        let vm = LoginViewModel(authService: AlwaysNetworkErrorAuthService())
        vm.email = "user@example.com"
        vm.password = "password"
        let result = await vm.login()
        XCTAssertFalse(result)
        XCTAssertEqual(vm.errorMessage, "timeout")
    }
}

// MARK: - AuthViewModelTests

@MainActor
final class AuthViewModelTests: XCTestCase {

    // MARK: Session Restoration

    func test_authViewModel_init_tokenNil_notAuthenticated() {
        let vm = AuthViewModel(authService: StubAuthService(stubToken: nil))
        XCTAssertFalse(vm.isAuthenticated)
    }

    func test_authViewModel_init_tokenPresent_isAuthenticated() {
        let vm = AuthViewModel(authService: StubAuthService(stubToken: "abc"))
        XCTAssertTrue(vm.isAuthenticated)
    }

    func test_authViewModel_init_tokenPresent_restoresCurrentUser() {
        let user = User(id: "1", name: "X", email: "x@x.com")
        let vm = AuthViewModel(authService: StubAuthService(stubToken: "abc", stubUser: user))
        XCTAssertEqual(vm.currentUser?.name, "X")
    }

    // MARK: didLoginSuccessfully

    func test_authViewModel_didLoginSuccessfully_setsIsAuthenticated() {
        let stub = StubAuthService(stubToken: nil)
        let vm = AuthViewModel(authService: stub)
        XCTAssertFalse(vm.isAuthenticated)
        stub.stubToken = "abc"
        vm.didLoginSuccessfully()
        XCTAssertTrue(vm.isAuthenticated)
    }

    func test_authViewModel_didLoginSuccessfully_setsCurrentUser() {
        let user = User(id: "2", name: "Bob", email: "bob@example.com")
        let stub = StubAuthService(stubToken: nil)
        let vm = AuthViewModel(authService: stub)
        stub.stubToken = "abc"
        stub.stubUser = user
        vm.didLoginSuccessfully()
        XCTAssertEqual(vm.currentUser?.email, "bob@example.com")
    }

    // MARK: Logout

    func test_authViewModel_logout_clearsIsAuthenticated() {
        let stub = StubAuthService(stubToken: "abc")
        let vm = AuthViewModel(authService: stub)
        XCTAssertTrue(vm.isAuthenticated)
        vm.logout()
        XCTAssertFalse(vm.isAuthenticated)
    }

    func test_authViewModel_logout_clearsCurrentUser() {
        let user = User(id: "3", name: "Jane", email: "jane@example.com")
        let stub = StubAuthService(stubToken: "abc", stubUser: user)
        let vm = AuthViewModel(authService: stub)
        XCTAssertNotNil(vm.currentUser)
        vm.logout()
        XCTAssertNil(vm.currentUser)
    }
}
