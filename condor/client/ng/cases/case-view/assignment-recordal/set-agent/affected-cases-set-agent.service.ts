import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class AffectedCasesSetAgentService {
    constructor(private readonly http: HttpClient) { }

    setAgent(agentId: number, mainCaseId: number, isCaseNameSet: boolean, rows: Array<string>): Observable<any> {
        return this.http.post('api/case/affectedCases/setAgent', {
            agentId,
            mainCaseId,
            isCaseNameSet,
            affectedCases: rows
        });
    }

    getCaseReference = (caseKey: number): Observable<string> => {
        return this.http.get<string>(`api/case/getCaseRefAndNameType/${caseKey}`);
    };
}