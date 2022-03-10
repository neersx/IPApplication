import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class CaseBillNarrativeService {
    constructor(private readonly http: HttpClient) { }

    getCaseNarativeDefaults = (caseKey: number): Observable<string> => {
        return this.http.get<string>(`api/accounting/getCaseBillNarrativeDefaults/${caseKey}`);
    };

    getAllCaseNarratives = (caseKey: number): Observable<string> => {
        return this.http.get<string>(`api/accounting/getAllCaseBillNarratives/${caseKey}`);
    };

    deleteCaseBillNarrative = (data: any): Observable<any> => {
        return this.http.post('api/accounting/deleteCaseBillNarrative', {
            caseKey: data.caseKey,
            language: data.language
        });
    };

    setCaseBillNarrative = (data: any): Observable<any> => {
        return this.http.post('api/accounting/setCaseBillNarrative', {
            caseKey: data.caseKey,
            language: data.language,
            notes: data.notes
        });
    };
}