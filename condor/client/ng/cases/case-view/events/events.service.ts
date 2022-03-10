import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class CaseViewEventsService {
    constructor(private readonly $http: HttpClient) {
    }

    getCaseViewOccurredEvents = (caseKey: number, importanceLevel: number, queryParams: any): Observable<any> => {
        return this.$http.get('api/case/' + caseKey + '/caseviewevent/occurred', {
            params: {
                q: JSON.stringify({
                    importanceLevel
                }),
                params: JSON.stringify(queryParams)
            }
        });
    };

    getCaseViewDueEvents = (caseKey: number, importanceLevel: number, queryParams: any): Observable<any> => {
        return this.$http.get('api/case/' + caseKey + '/caseviewevent/due', {
            params: {
                q: JSON.stringify({
                    importanceLevel
                }),
                params: JSON.stringify(queryParams)
            }
        });
    };

    siteControlId(): Observable<number> {
        return this.$http.get<number>('api/case/eventNotesDetails/siteControlId');
    }
}