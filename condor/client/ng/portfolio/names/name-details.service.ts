import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { EmailTemplate } from 'shared/component/forms/ipx-email-link/email-template';

export interface INameDetailsService {
    getFirstEmailTemplate(caseId: number, nameType: string, sequence: number): Observable<EmailTemplate>;
}

@Injectable()
export class NameDetailsService {
    constructor(private readonly http: HttpClient) {}

    getFirstEmailTemplate = (caseKey: number, nameType: string, sequence: number): Observable<EmailTemplate> => {
    return this.http.get<EmailTemplate>('api/case/' + encodeURI(caseKey.toString()) + '/names/email-template', {
        params: {
            params: JSON.stringify({
                caseKey,
                nameType,
                sequence
            }),
            resolve: JSON.stringify(sequence == null)
        }
    });
    };
}
