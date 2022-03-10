import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class AuthenticationService {
  constructor(private readonly http: HttpClient) { }

  getOptions = () => {
    let options: { userAgent: any; systemInfo?: any; signInOptions?: any; resource: any };

    return this.http.get('../api/signin/options')
      .toPromise()
      .then((response: any) => {
        options = {
          userAgent: response.userAgent,
          systemInfo: response.systemInfo,
          signInOptions: response.result,
          resource: response.__resources
        };

        if (!options.userAgent.languages || options.userAgent.languages.length === 0) {
          options.userAgent.languages = ['en'];
        }
        const appSettings = {
          key: response.instrumentationKey,
          sessionTracking: response.sessionTracking,
          exceptionTracking: response.exceptionTracking,
          performanceTracking: response.performanceTracking
        };

        localStorage.appInsightsSettings = JSON.stringify(appSettings) || 'NOT_AVAILABLE';
      }).then((): any => options);
  };

  signin = (uri: string, username: string, password: string, returnUrl: string, code: string, preference: string) => this.http.post(uri, {
    username,
    password,
    returnUrl,
    code,
    preference
  }).toPromise()
    .then((response) => response);

  signinWindows = (api: string) => (this.http.post(api, {}));
}
