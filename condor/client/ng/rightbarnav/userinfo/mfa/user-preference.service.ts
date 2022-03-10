import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class UserPreferenceService {

  constructor(private readonly http: HttpClient) { }
  GetUserTwoFactorAuthPreferences(): any {
    let options: { configuredModes: Array<string>; preference: string; enabled: boolean };

    return this.http.get('api/twoFactorAuthPreference')
      .toPromise()
      .then((response: any) => {
        options = {
          configuredModes: response.configuredModes,
          preference: response.preference,
          enabled: response.enabled
        };
      }).then(() => options);
  }

  SetUserTwoFactorAuthPreferences(preference: { Preference: string }): Promise<any> {
    return this.http.put('api/twoFactorAuthPreference', preference).toPromise().then(() => true);
  }

  RemoveTwoFactorAppConfiguration(): Promise<boolean> {
    return this.http.post('api/twoFactorAuthPreference/twoFactorAppKeyDelete', {}).toPromise().then(() => true);
  }
}
