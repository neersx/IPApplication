import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export type PasswordManagementResponse = {
    status?: string;
    passwordPolicyValidationErrorMessage?: string;
    hasPasswordReused?: boolean;
};

@Injectable()
export class ResetPasswordService {
    constructor(private readonly http: HttpClient) { }

    sendEmail = (username: string, url: string): Observable<any> => {
        const pathWithoutQueryString = url.substring(0, url.indexOf('?'));

        return this.http.post('../api/resetpassword/sendlink', { username, url: pathWithoutQueryString });
    };

    updatePassword = (token: string, newPassword: string, confirmPassword: string, oldPassword: string, isPasswordExpired: boolean): Observable<PasswordManagementResponse> => {
        return this.http.post<PasswordManagementResponse>('../api/resetpassword', { token, newPassword, confirmPassword, oldPassword, isPasswordExpired });
    };
}