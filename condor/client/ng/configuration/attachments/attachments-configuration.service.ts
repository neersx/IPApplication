import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable()
export class AttachmentConfigurationService {
    private readonly hasPendingChangesSubject = new BehaviorSubject<boolean>(false);
    private readonly hasErrorsSubject = new BehaviorSubject<boolean>(false);

    hasPendingChanges$ = this.hasPendingChangesSubject.asObservable();
    hasErrors$ = this.hasErrorsSubject.asObservable();

    states = {
        hasPendingChanges: undefined,
        hasErrors: undefined
    };

    constructor(private readonly http: HttpClient) { }

    save$ = (items: any): Observable<any> => {
        return this.http.put('api/configuration/attachments/settings', items);
    };

    refreshCache$ = (): Observable<any> => {
        return this.http.get('api/configuration/attachments/settings/refreshcache');
    };

    validateUrl$ = (path: string, networkDrives: Array<any>): Observable<boolean> => {
        return this.http.post<boolean>('api/configuration/attachments/settings/validatepath', { path, networkDrives });
    };

    resetChangeEventState = () => {
        this.states.hasPendingChanges = undefined;
        this.states.hasErrors = undefined;
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
}