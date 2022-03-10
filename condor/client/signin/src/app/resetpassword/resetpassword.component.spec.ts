import { of } from 'rxjs';
import { ResetPasswordComponent } from './resetpassword.component';
import { ActivatedRouteMock, AuthenticationServiceMock, ChangeDetectorRefMock, ResetPasswordServiceMock, RouterMock, TranslateServiceMock } from './resetpassword.mock';

describe('ResetPasswordComponent', () => {
  let component: ResetPasswordComponent;
  let routerMock: RouterMock;
  let routeMock: ActivatedRouteMock;
  let serviceMock: ResetPasswordServiceMock;
  let translateMock: TranslateServiceMock;
  let authServiceMock: AuthenticationServiceMock;
  let cdRefMock: ChangeDetectorRefMock;
  beforeEach(() => {
    routerMock = new RouterMock();
    routeMock = new ActivatedRouteMock();
    serviceMock = new ResetPasswordServiceMock();
    translateMock = new TranslateServiceMock();
    cdRefMock = new ChangeDetectorRefMock();
    authServiceMock = new AuthenticationServiceMock();
    component = new ResetPasswordComponent(
      routerMock as any,
      routeMock as any,
      serviceMock as any,
      translateMock as any,
      authServiceMock as any,
      cdRefMock as any);

  });

  it('should create', () => {
    expect(component).toBeDefined();
    expect(component.formData).toBeDefined();
  });

  it('validate ngOnInit', () => {
    component.ngOnInit();
    expect(routeMock.queryParamMap.subscribe).toHaveBeenCalled();
    expect(authServiceMock.getOptions).toHaveBeenCalled();
  });

  it('validate isCredentialValid with blank username', () => {
    component.formData.userName = undefined;
    const result = component.isCredentialValid();
    expect(result).toBeFalsy();
  });

  it('validate isCredentialValid with valid username', () => {
    component.formData.userName = 'username';
    const result = component.isCredentialValid();
    expect(result).toBeTruthy();
  });

  it('validate cancel', () => {
    component.cancel();
    expect(routerMock.navigateByUrl).toHaveBeenCalled();
  });

  it('validate send with valid username', () => {
    component.formData.userName = 'username';
    component.send();
    expect(serviceMock.sendEmail).toHaveBeenCalled();
  });

  it('validate send with blank username', () => {
    component.formData.userName = undefined;
    component.cookieConsent.consented = true;
    component.send();
    expect(component.formData.success).toEqual('');
    expect(component.formData.error).toEqual('requiredLoginId');
  });

  it('validate clearError', () => {
    component.formData.error = 'requiredUserName';
    component.formData.errorFromServer = 'requiredUserName';
    component.clearError();
    expect(component.formData.error).toBeUndefined();
    expect(component.formData.errorFromServer).toBeUndefined();
  });

  it('validate showChangePasswordPanel with token', () => {
    component.token = 'test-token';
    const result = component.showChangePasswordPanel();
    expect(result).toBeTruthy();
  });

  it('validate showChangePasswordPanel with blank token', () => {
    component.token = null;
    const result = component.showChangePasswordPanel();
    expect(result).toBeFalsy();
  });

  it('validate save with blank newPassword', () => {
    component.formData.userName = 'username';
    component.formData.newPassword = undefined;
    component.formData.confirmPassword = 'password';
    component.save();
    expect(component.formData.error).toEqual('newPasswordRequired');
  });

  it('validate save with blank confirmPassword', () => {
    component.formData.userName = 'username';
    component.formData.newPassword = 'password';
    component.formData.confirmPassword = undefined;
    component.save();
    expect(component.formData.error).toEqual('confirmPasswordRequired');
  });

  it('validate save with blank old password and expired flag', () => {
    component.formData.userName = 'username';
    component.formData.newPassword = 'password';
    component.formData.confirmPassword = undefined;
    component.formData.oldPassword = undefined;
    component.isExpired = true;
    component.save();
    expect(component.formData.error).toEqual('oldPasswordRequired');
  });

  it('validate save with old pasword and expired flag', () => {
    component.formData.userName = 'username';
    component.formData.newPassword = 'password';
    component.formData.confirmPassword = 'password';
    component.formData.oldPassword = 'oldpassword';
    component.isExpired = true;
    component.save();
    expect(serviceMock.updatePassword).toHaveBeenCalled();
  });

  it('validate save with mismatch newPassword and confirmPassword', () => {
    component.formData.userName = 'username';
    component.formData.newPassword = 'password';
    component.formData.confirmPassword = 'password123';
    component.save();
    expect(component.formData.error).toEqual('passwordMismatch');
  });

  it('validate save with valid formdata', () => {
    component.formData.userName = 'username';
    component.formData.newPassword = 'password';
    component.formData.confirmPassword = 'password';
    component.save();
    expect(serviceMock.updatePassword).toHaveBeenCalled();
  });

  it('validate changeDivColor with success', () => {
    component.formData.success = 'resetPasswordSuccessful';
    const result = component.changeDivColor();
    expect(result).toEqual('col-xs-8 col-sm-5 col-md-4 col-lg-3');
  });
  it('call translate service if save is successful', () => {
    component.formData.userName = 'username';
    component.formData.newPassword = 'password';
    component.formData.confirmPassword = 'password';
    serviceMock.updatePassword.mockReturnValue(of({ status: 'success' }));
    component.save();
    expect(serviceMock.updatePassword).toHaveBeenCalled();
    expect(translateMock.get).toHaveBeenCalled();
  });
  it('Set formdata error save is unsuccessful', () => {
    component.formData.userName = 'username';
    component.formData.newPassword = 'password';
    component.formData.confirmPassword = 'password';
    serviceMock.updatePassword.mockReturnValue(of({ status: 'passwordPolicyValidationFailed' }));
    component.save();
    expect(serviceMock.updatePassword).toHaveBeenCalled();
    expect(component.formData.error).toBe('passwordPolicy-heading');

    serviceMock.updatePassword.mockReturnValue(of({ status: 'error' }));
    component.save();
    expect(component.formData.error).toBe('error');
  });
});
