import { HttpClient } from '@angular/common/http';
import { Injectable, NgZone } from '@angular/core';
import { AppContextService } from 'core/app-context.service';
import { MessageBroker } from 'core/message-broker';
import { WindowRef } from 'core/window-ref';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { DmsViewData } from './dms-view-data';

@Injectable()
export class DmsService {
    isOAuth2Authenticated$ = new BehaviorSubject(true);
    isOAuth2Error$ = new BehaviorSubject(false);

    ctx: any;
    binding: string;
    subscription: any;
    constructor(private readonly http: HttpClient, private readonly messageBroker: MessageBroker, private readonly zone: NgZone, private readonly winRef: WindowRef, private readonly appContextService: AppContextService) {
        this.appContextService.appContext$
            .pipe(take(1))
            .subscribe(ctx => {
                this.ctx = ctx;
            });
    }

    private readonly getApiWithType = ({ callerType }: DmsCallerType): string => {
        const type = callerType === 'NameView' ? 'name' : 'case';

        return `api/${type}`;
    };

    getViewData$ = (): Observable<DmsViewData> => {
        return this.http.get<DmsViewData>('api/document-management/view-data');
    };

    getDmsFolders$ = (caller: DmsCallerType, caseKey: number): Observable<any> => {
        const url = `${this.getApiWithType(caller)}/${caseKey}/document-management/folders`;

        return this.requestAuthorizationIfRequired(this.http.get(url));
    };

    getDmsChildFolders$ = (databaseRowId: number, containerId: string, folderType: string, fetchChild: boolean): Observable<any> => {
        const url = `api/document-management/folder/${databaseRowId}-${containerId}/${fetchChild}`;

        return this.requestAuthorizationIfRequired(this.http.get(url, {
            params: {
                options: JSON.stringify({ folderType })
            }
        }));
    };

    getDmsDocuments$ = (siteDbId: number, containerId: string, queryParams: GridQueryParameters, folderType: string): Observable<any> => {
        const url = `api/document-management/documents/${siteDbId}-${containerId}`;

        const results = this.requestAuthorizationIfRequired(this.http.get(url, {
            params: {
                params: JSON.stringify(queryParams),
                options: JSON.stringify({ folderType })
            }
        }), true);

        return results;
    };

    getDmsDocumentDetails$ = (siteDbId: number, containerId: string): Observable<any> => {
        const url = `api/document-management/document/${siteDbId}-${containerId}`;

        return this.requestAuthorizationIfRequired(this.http.get(url));
    };

    private readonly requestAuthorizationIfRequired = (action: Observable<any>, pagingRequired = false): Observable<any> => {
        return action.pipe(map((data: any) => {
            if (data.isAuthRequired === true) {
                this.isOAuth2Authenticated$.next(false);
                this.isOAuth2Error$.next(true);
            }

            return pagingRequired ? data : data.data || data;
        }));
    };

    loginDms = (databaseSettings?: any): Promise<boolean> => {
        this.isOAuth2Error$.next(false);

        return new Promise((resolve) => {
            this.binding = 'dms.oauth2.login.' + this.ctx.user.identityId;
            this.messageBroker.subscribe(this.binding, (data) => {
                this.zone.runOutsideAngular(() => {
                    if (data && data.status === 'Complete') {
                        this.isOAuth2Authenticated$.next(true);
                        this.isOAuth2Error$.next(false);
                        resolve(true);
                    }
                    if (data && data.status === 'Failed') {
                        this.isOAuth2Error$.next(true);
                        resolve(false);
                    }
                });
            });
            this.messageBroker.connect();
            this.navigateWithTimeInterval(databaseSettings);
        });
    };

    navigateWithTimeInterval = (databaseSettings): void => {
        const interval = setInterval(() => {
            const connectionId = this.messageBroker.getConnectionId();
            if (connectionId) {
                clearInterval(interval);
                const url = './api/dms/authorize/';
                this.http.post('api/dms/settings?connectionId=' + connectionId, databaseSettings).toPromise().then(() => {
                    const w = this.winRef.nativeWindow.open(url + encodeURIComponent(connectionId), '_blank');
                    if (w) {
                        w.onerror = () => console.log('error occurred');
                    }
                });
            }
        }, 200);
    };

    disconnectBindings = (): void => {
        this.messageBroker.disconnectBindings([this.binding]);
    };
}

export type DmsCallerType = {
    callerType: 'CaseView' | 'NameView'
};