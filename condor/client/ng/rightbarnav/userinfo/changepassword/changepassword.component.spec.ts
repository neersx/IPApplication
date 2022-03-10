
import { FormControl, NgForm, Validators } from '@angular/forms';
import { NotificationServiceMock } from 'ajs-upgraded-providers/notification-service.mock';
import { BsModalRefMock, ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { ChangePasswordComponent } from './changepassword.component';
import { ChangePasswordServiceMock } from './changepasswordservice.mock';

describe('ChangepasswordComponent', () => {
    let component: ChangePasswordComponent;
    const bsModalRefMock = new BsModalRefMock();
    const changePasswordServiceMock = new ChangePasswordServiceMock();
    const notificationServiceMock = new NotificationServiceMock();
    const changeDetectorRefMock = new ChangeDetectorRefMock();
    const translateMock = new TranslateServiceMock();

    beforeEach(() => {
        component = new ChangePasswordComponent(bsModalRefMock as any,
            changePasswordServiceMock as any,
            notificationServiceMock as any,
            changeDetectorRefMock as any,
            translateMock as any);
        component.ngForm = new NgForm(null, null);
        component.ngForm.form.addControl('oldPassword', new FormControl(null, Validators.required));
        component.ngForm.form.addControl('newPassword', new FormControl(null, Validators.required));
        component.ngForm.form.addControl('confirmNewPassword', new FormControl(null, Validators.required));
    });

    it('should create', () => {
        expect(component).toBeDefined();
        expect(component.formData).toBeDefined();
    });

    it('validate verifyPassword method with positive result', () => {
        component.formData.newPassword = 'password';
        component.formData.confirmNewPassword = 'password';
        const result = component.verifyPassword();
        expect(component.ngForm.controls.confirmNewPassword.valid).toBeTruthy();
        expect(result).toBeTruthy();
    });

    it('validate verifyPassword method with negative result', () => {
        component.formData.newPassword = 'password';
        component.formData.confirmNewPassword = 'password1';
        const result = component.verifyPassword();
        expect(component.ngForm.controls.confirmNewPassword.valid).toBeFalsy();
        expect(result).toBeFalsy();
    });

    it('validate close method', () => {
        component.close();
        expect(bsModalRefMock.hide).toHaveBeenCalled();
    });
    it('validate submit method with newPassword is blank', () => {
        component.formData.oldPassword = undefined;
        component.formData.newPassword = '123';
        component.formData.confirmNewPassword = '123';
        component.submit();
        expect(component.ngForm.form.valid).toBeFalsy();
    });

    it('validate submit method when new and confirm passwords do not match', () => {
        component.formData.oldPassword = 'password';
        component.formData.newPassword = 'password';
        component.formData.confirmNewPassword = 'password1';
        component.submit();
        expect(component.ngForm.form.valid).toBeFalsy();
    });
    describe('formdata is succesful', () {
        beforeEach(() => {
            component.formData.oldPassword = 'password';
            component.formData.newPassword = '123';
            component.formData.confirmNewPassword = '123';
            component.ngForm.controls.oldPassword.setValue('password');
            component.ngForm.controls.newPassword.setValue('123');
            component.ngForm.controls.confirmNewPassword.setValue('123');
        });
        it('validate submit method with changePasswordService to be called', () => {
            changePasswordServiceMock.updateUserPassword.mockReturnValue(of({status: 'success'}));
            component.submit();
            expect(changePasswordServiceMock.updateUserPassword).toHaveBeenCalled();
            expect(notificationServiceMock.success).toHaveBeenCalled();
            expect(bsModalRefMock.hide).toHaveBeenCalled();
        });
        it('Set formdata error save is unsuccessful', () => {
            changePasswordServiceMock.updateUserPassword.mockReturnValue(of({status: 'passwordPolicyValidationFailed'}));
            component.submit();
            expect(changePasswordServiceMock.updateUserPassword).toHaveBeenCalled();
            expect(component.formData.error).toBe('signin.passwordPolicy-heading');

            changePasswordServiceMock.updateUserPassword.mockReturnValue(of({status: 'passwordPolicyValidationFailed', hasPasswordReused: true, passwordPolicyValidationErrorMessage: '5'}));
            component.submit();
            expect(changePasswordServiceMock.updateUserPassword).toHaveBeenCalled();
            expect(component.formData.error).toBe('5');

            changePasswordServiceMock.updateUserPassword.mockReturnValue(of({status: 'error'}));
            component.submit();
            expect(component.formData.error).toBe('signin.error');
        });
    });
});