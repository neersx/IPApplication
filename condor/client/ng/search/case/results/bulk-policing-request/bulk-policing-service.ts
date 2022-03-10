import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { BulkUpdateReasonData, DropDownData } from 'search/case/bulk-update/bulk-update.data';

@Injectable()
export class BulkPolicingService {
    constructor(private readonly http: HttpClient) { }

    getBulkPolicingViewData(): Observable<BulkPolicingViewData> {
        return this.http.get<BulkPolicingViewData>('api/search/case/bulkupdate/policingData');
    }

    sendBulkPolicingRequest(caseIds: Array<number>, caseAction: string, reasonData: BulkUpdateReasonData): Observable<any> {
        return this.http.post('api/search/case/bulkupdate/save', {
            caseIds,
            caseAction,
            reasonData
        });
    }
}

export class BulkPolicingViewData {
    textTypes: Array<DropDownData>;
    allowRichText: boolean;
}