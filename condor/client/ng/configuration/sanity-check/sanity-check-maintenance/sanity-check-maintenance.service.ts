import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import * as _ from 'underscore';

type TopicState = {
    hasPendingChanges: undefined | boolean,
    hasErrors: undefined | boolean,
    isValid: undefined | boolean
};
@Injectable()
export class SanityCheckMaintenanceService {
    private readonly hasPendingChangesSubject = new BehaviorSubject<boolean>(false);
    private readonly hasErrorsSubject = new BehaviorSubject<boolean>(false);
    private cache: Map<string, TopicState> = new Map<string, TopicState>();

    hasPendingChanges$ = this.hasPendingChangesSubject.asObservable();
    hasErrors$ = this.hasErrorsSubject.asObservable();

    private states = {
        hasPendingChanges: undefined,
        hasErrors: undefined
    };

    constructor(private readonly http: HttpClient) { }

    getViewData$(matchType: string, id: any = null): Observable<any> {
        return this.http.get<any>(`api/configuration/sanity-check/maintenance/${matchType}${!!id ? '/' + id : ''}`);
    }

    save$ = (matchType: string, items: any): Observable<any> => {
        return this.http.post(`api/configuration/sanity-check/maintenance/${matchType}`, items);
    };

    update$ = (matchType: string, data: any): Observable<any> => {
        return this.http.put(`api/configuration/sanity-check/maintenance/${matchType}`, data);
    };

    resetChangeEventState = () => {
        this.cache = new Map<string, TopicState>();
        this.states = {
            hasPendingChanges: undefined,
            hasErrors: undefined
        };
    };

    raiseStatus = (topicKey: string, hasPendingChanges: boolean, hasErrors: boolean, isValid: boolean) => {
        const newState = { hasPendingChanges, hasErrors, isValid };
        let state = this.cache.has(topicKey) ? this.cache.get(topicKey) : newState;
        state = { ...state, ...newState };

        this.cache.set(topicKey, state);

        this.raisePendingChanges(Array.from(this.cache.values()).some(d => d.hasPendingChanges));
        this.raiseHasErrors(Array.from(this.cache.values()).some(d => d.hasErrors || !d.isValid));
    };

    private readonly raisePendingChanges = (hasPendingChanges: boolean) => {
        if (hasPendingChanges !== this.states.hasPendingChanges) {
            this.states.hasPendingChanges = hasPendingChanges;
            this.hasPendingChangesSubject.next(hasPendingChanges);
        }
    };

    private readonly raiseHasErrors = (hasErrors: boolean) => {
            this.hasErrorsSubject.next(hasErrors);
    };
}