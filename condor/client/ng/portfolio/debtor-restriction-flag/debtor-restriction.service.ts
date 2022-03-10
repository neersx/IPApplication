import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

export interface IDebtorRestriction {
    debtor: number;
    severity: string;
    description: string;
}

export interface IDebtorRestrictionsService {
    getRestrictions(nameKey: number): Observable<IDebtorRestriction>;
}

@Injectable()
export class DebtorRestrictionsService {
    private readonly cache: {[nameKey: number]: IDebtorRestriction} = {};
    constructor(private readonly http: HttpClient) {}
    getRestrictions = (nameKey: number): Observable<Array<IDebtorRestriction>> => {
        const cached = this.cache[nameKey];
        if (cached) {
            return of([cached]);
        }

        return this.http
            .get<Array<IDebtorRestriction>>('api/names/restrictions', {
                params: new HttpParams().set('ids', [nameKey].join(','))
            })
            .pipe(
                tap((x: Array<IDebtorRestriction>) => {
                    this.cache[nameKey] = x[0];
                })
            );
    };
}
