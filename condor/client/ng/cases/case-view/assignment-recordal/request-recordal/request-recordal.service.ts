import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { RecordalRequest, RecordalRequestType } from '../affected-cases.model';

@Injectable()
export class RequestRecordalService {
    constructor(private readonly http: HttpClient) { }

    getCaseReference = (caseKey: number): Observable<string> => {
        return this.http.get<string>(`api/case/getCaseReference/${caseKey}`);
    };

    getRequestRecordal = (request: RecordalRequest): Observable<any> => {
        return this.http.post('api/case/requestRecordal', {
            caseId: request.caseId,
            selectedRowKeys: request.selectedRowKeys,
            deSelectedRowKeys: request.deSelectedRowKeys,
            isAllSelected: request.isAllSelected,
            requestType: request.requestType,
            filter: request.filter
        });
    };

    onSaveRecordal = (caseId: number, seqIds: Array<number>, requestedDate: Date, requestType: RecordalRequestType): Observable<any> => {
        return this.http.post('api/case/saveRecordal', {
            caseId,
            seqIds,
            requestedDate,
            requestType
        });
    };
}