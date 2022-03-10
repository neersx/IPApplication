import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface IChangePasswordService {
  updateUserPassword(request: any): Observable<any>;
}

export type PasswordManagementResponse = {
  status?: string;
  passwordPolicyValidationErrorMessage?: string;
  hasPasswordReused?: boolean;
};

@Injectable()
export class ChangePasswordService implements IChangePasswordService {

  constructor(private readonly http: HttpClient) {
  }

  updateUserPassword = (request: any): Observable<PasswordManagementResponse> => {
    return this.http.post<PasswordManagementResponse>('api/passwordManagement/updateUserPassword', request);
  };
}
