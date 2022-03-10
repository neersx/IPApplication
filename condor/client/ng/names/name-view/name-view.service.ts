import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

@Injectable()
export class NameViewService {
    enableSave = new BehaviorSubject(false);
    savedSuccessful = new BehaviorSubject(false);
    resetChanges = new BehaviorSubject(false);

    constructor(private readonly http: HttpClient) {
    }

    getNameViewData$(nameId: Number, programId?: string): Observable<any> {
        return this.http.get('api/name/nameview/' + encodeURI(nameId.toString()) + '/' + (programId ? encodeURI(programId) : ''));
    }

    getSupplierDetails$(nameId: Number): Observable<any> {
        return this.http.get('api/name/' + encodeURI(nameId.toString()) + '/supplier-details');
    }

    getNameInternalDetails$(nameId: Number): Observable<any> {
        return this.http.get('api/name/' + encodeURI(nameId.toString()) + '/internal-details');
    }

    maintainName$(data: any): Observable<any> {
        return this.http.post('api/name/nameview/maintenance/', data);
    }

    getTrustAccounting$(nameId: Number, queryParams: GridQueryParameters): Observable<any> {
        return this.http.post('api/name/' + encodeURI(nameId.toString()) + '/trust-accounting',  queryParams);
    }

    getTrustAccountingDetails$(nameId: Number, bankId: Number, bankSeqId: Number, entityId: Number, queryParams: any): Observable < any > {
        return this.http.get('api/name/trust-accounting-details/', {
            params: new HttpParams()
            .set('nameId', JSON.stringify(nameId))
            .set('bankId', JSON.stringify(bankId))
            .set('bankSeqId', JSON.stringify(bankSeqId))
            .set('entityId', JSON.stringify(entityId))
            .set('params', JSON.stringify(queryParams))
        });
    }
}