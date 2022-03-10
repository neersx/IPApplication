import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class TwoFactorAppConfigurationService {
  constructor(private readonly http: HttpClient) { }

  GetTwoFactorTempKey(): Observable<string> {
    return this.http.get<string>('api/twoFactorAuthPreference/twoFactorTempKey');
  }

  VerifyAndSaveTempKey(appCode: string): Promise<{ status: string }> {
    let response: { status: string };

    return this.http.post('api/twoFactorAuthPreference/twoFactorTempKeyVerify', { appCode })
      .toPromise().then((res: any) => {
        response = {
          status: res.status
        };
      })
      .then(() => response);
  }
}
