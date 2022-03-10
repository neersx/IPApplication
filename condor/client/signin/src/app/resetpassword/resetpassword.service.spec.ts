import { of } from 'rxjs';
import { PasswordManagementResponse, ResetPasswordService } from './resetpassword.service';

describe('ResetPasswordService', () => {
    let service: ResetPasswordService;
    let httpClientSpy;
    beforeEach(() => {
        httpClientSpy = { get: jest.fn(), post: jest.fn() };
        service = new ResetPasswordService(httpClientSpy);
    });
    it('should call sendEmail', () => {
        const response = { status: 'success' };
        httpClientSpy.post.mockReturnValue(of(response));
        const username = 'abc';
        const url = 'api/resetpassword?id=1';
        service.sendEmail(username, url).subscribe(
            result => expect(result).toEqual(response)
        );
        expect(httpClientSpy.post).toHaveBeenCalledWith('../api/resetpassword/sendlink', { username, url: 'api/resetpassword' });
    });
    it('should call updatePassword', () => {
        const response: PasswordManagementResponse = { status: 'success' };
        httpClientSpy.post.mockReturnValue(of(response));
        const token = '12332112';
        const newPassword = 'abc';
        const confirmPassword = 'abc';
        const oldPassword = 'old';
        const isPasswordExpired = false;
        service.updatePassword(token, newPassword, confirmPassword, oldPassword, isPasswordExpired).subscribe(
            result => expect(result).toEqual(response)
        );
        expect(httpClientSpy.post).toHaveBeenCalledWith('../api/resetpassword', { token, newPassword, confirmPassword, oldPassword, isPasswordExpired });
    });
});