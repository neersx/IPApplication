import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class AdjustWipService {

    constructor(private readonly http: HttpClient) { }
    url = 'api/accounting/wip-adjustments';

    getAdjustWipSupportData$ = (): Observable<any> => {
        return this.http.get<any>(this.url + '/view-support');
    };

    getItemForWipAdjustment$ = (entityKey: number, transKey: number, wipSeqKey: number): Observable<any> => {
        return this.http.get(`${this.url}/adjust-item`, {
            params: {
                entityKey: entityKey.toString(),
                transKey: transKey.toString(),
                wipSeqKey: wipSeqKey.toString()
            }
        });
    };

    validateItemDate(date: any): any {
        return this.http.get(`${this.url}/validate`, {
            params: {
                itemDate: date.toString()
            }
        });
    }

    submitAdjustWip(data: any): Observable<any> {
        return this.http.post(`${this.url}/adjust-item`, data);
    }
}
