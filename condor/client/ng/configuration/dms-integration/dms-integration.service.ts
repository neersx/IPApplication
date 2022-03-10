import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { DmsService } from 'common/case-name/dms/dms.service';
import { BehaviorSubject, Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class DmsIntegrationService {
    private readonly hasPendingChangesSubject = new BehaviorSubject<boolean>(false);
    private readonly hasErrorsSubject = new BehaviorSubject<boolean>(false);
    username: string;
    password: string;
    hasPendingDatabaseChanges$ = new BehaviorSubject(false);
    hasPendingChanges$ = this.hasPendingChangesSubject.asObservable();
    hasErrors$ = this.hasErrorsSubject.asObservable();

    states = {
        hasPendingChanges: undefined,
        hasErrors: undefined
    };

    constructor(private readonly http: HttpClient, private readonly service: DmsService) { }

    getCredentials = (): { username?: string, password?: string } => {
        if (this.username || this.password) {
            return { username: this.username, password: this.password };
        }

        return null;
    };

    testConnections$ = (userName: string, password: string, items: Array<any>): Promise<Array<ConnectionResponseModel>> => {
        this.username = userName;
        this.password = password;

        const promises = items.map(database => {

            if (database.loginType !== 'OAuth 2.0') {
                return this.testConnection$(userName, password, database);
            }

            return this.service.loginDms([database]).then((success) => {
                if (success) {
                    return this.testConnection$(userName, password, database);
                }
                const i = new ConnectionResponseModel();
                i.success = false;
                i.errorMessages = ['failedConnection'];

                return Promise.resolve([i]);
            });
        });

        return Promise.all(promises).then(values => [].concat.apply([], values));
    };

    private readonly testConnection$ = (userName: string, password: string, item: any): Promise<Array<ConnectionResponseModel>> => {
        return this.http.put<Array<ConnectionResponseModel>>('api/configuration/dms-integration/settings/testConnection', { userName, password, settings: [item] }).pipe(tap(responses => {
            if (responses.find(response => !response.success)) {
                this.username = null;
                this.password = null;
            }

            return responses;
        })).toPromise();
    };

    validateUrl$ = (url: string, integrationType: string): Observable<boolean> => {
        return this.http.post<boolean>('api/configuration/DMSIntegration/settings/validateurl', { url, integrationType });
    };

    save$ = (items: any): Observable<any> => {
        return this.http.put('api/configuration/DMSIntegration/settings', items);
    };

    testCaseWorkspace$ = (caseKey: number, items: any, signInToDms: boolean): Promise<any> => {
        if (signInToDms) {
            return this.service.loginDms().then(
                () => this.http.post('api/case/testCaseFolders/' + encodeURI(caseKey.toString()), items).toPromise()
            );
        }

        return this.http.post('api/case/testCaseFolders/' + encodeURI(caseKey.toString()), items).toPromise();
    };

    testNameWorkspace$ = (nameKey: number, items: any, signInToDms: boolean): Promise<any> => {
        if (signInToDms) {
            return this.service.loginDms().then(
                () => this.http.post('api/name/testNameFolders/' + encodeURI(nameKey.toString()), items).toPromise()
            );
        }

        return this.http.post('api/name/testNameFolders/' + encodeURI(nameKey.toString()), items).toPromise();
    };

    sendAllToDms$ = (dataSource: string): Observable<any> => {
        return this.http.post('api/dms/send/' + dataSource, null);
    };

    acknowledge$ = (jobExecutionId: string): Observable<any> => {
        return this.http.post('api/dms/job/' + jobExecutionId + '/status', null);
    };

    raisePendingChanges = (hasPendingChanges: boolean) => {
        if (hasPendingChanges !== this.states.hasPendingChanges) {
            this.states.hasPendingChanges = hasPendingChanges;
            this.hasPendingChangesSubject.next(hasPendingChanges);
        }
    };

    raiseHasErrors = (hasErrors: boolean) => {
        if (hasErrors !== this.states.hasErrors) {
            this.states.hasErrors = hasErrors;
            this.hasErrorsSubject.next(hasErrors);
        }
    };

    getRequiresCredentials = (databases: Array<any>): { showUsername: boolean, showPassword: boolean } => {
        return {
            showUsername: databases.find(db => ['UsernamePassword', 'UsernameWithImpersonation'].find(_ => _ === db.loginType) != null) != null,
            showPassword: databases.find(db => ['UsernamePassword'].find(_ => _ === db.loginType) != null) != null
        };
    };

    getManifest = (dataItem: any): void => {
        this.http
            .post(
                'api/configuration/dms-integration/settings/get-yaml',
                dataItem,
                {
                    observe: 'response',
                    responseType: 'arraybuffer'
                }
            )
            .subscribe((response: any) => {
                this.handleExportResponse(response);
            });
    };

    getDataDownload = (dataSourceType: string): Observable<any> => {

        return this.http.get('api/configuration/DMSIntegration/settingsView/dataDownload?type=' + dataSourceType);
    };

    private readonly handleExportResponse = (response: any): void => {
        const headers = response.headers;
        const data: any = response.body;

        const filename = headers.get('x-filename');
        const contentType = headers.get('content-type');

        const blob = new Blob([data], { type: contentType });

        if (window.Blob && window.navigator.msSaveOrOpenBlob) {
            // for IE browser
            window.navigator.msSaveOrOpenBlob(blob, filename);
        } else {
            // for other browsers
            const linkElement = document.createElement('a');

            const fileURL = window.URL.createObjectURL(blob);
            linkElement.href = fileURL;
            linkElement.download = filename;
            linkElement.click();
        }
    };
}

export class ConnectionResponseModel {
    success: boolean;
    errorMessages: Array<string>;
}