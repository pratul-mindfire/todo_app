import XCTest
@testable import TodoApp

// MARK: - Mock Auth Services

final class AlwaysSucceedAuthService: AuthService {
    func login(email: String, password: String) async throws {}
}

final class AlwaysFailAuthService: AuthService {
    func login(email: String, password: String) async throws {
        throw AuthError.invalidCredentials
    }
}

final class SlowAuthService: AuthService {
    var didStart = false
    var didFinish = false
    func login(email: String, password: String) async throws {
        didStart = true
        didFinish = true
    }
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
}
