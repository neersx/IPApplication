import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ReportingServicesSetting, ReportingServicesViewData, SecurityElement } from './reporting-services-integration-data';

@Injectable()
export class ReportingIntegrationSettingsService {

    private readonly _baseUrl = 'api/configuration/reportingservicessetting';
    constructor(private readonly http: HttpClient) {
    }

    save = (settings: ReportingServicesSetting): Observable<any> => {
        return this.http.post(this._baseUrl + '/save', settings);
    };

    getSettings = (): Observable<ReportingServicesViewData> => {
        return this.http.get<ReportingServicesViewData>(this._baseUrl)
            .pipe(
                map((response: ReportingServicesViewData) => {
                    const viewData = {
                        settings: response.settings ? response.settings : new ReportingServicesSetting()
                    };
                    viewData.settings.security = viewData.settings.security ? viewData.settings.security : new SecurityElement();

                    return viewData;
                })
            );
    };

    testConnection = (settings: ReportingServicesSetting): Observable<any> => {
        return this.http.post<boolean>(this._baseUrl + '/connection', settings);
    };
}