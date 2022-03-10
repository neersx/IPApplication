import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { Observable } from 'rxjs';
import * as _ from 'underscore';
import { WipWarningData } from './warnings-model';

@Injectable()
export class WarningService {
    private readonly baseAccountingUrl = 'api/accounting';
    restrictOnWip: boolean;

    constructor(private readonly http: HttpClient,
        private readonly translate: TranslateService) { }

    validate(nameKey: number, password: string): any {
        const data = {
            nameId: nameKey,
            clearTextPassword: password
        };

        return this.http.post('api/accounting/warnings/validate/', data);
    }

    getWarningsForNames(nameKey: number, currentDate: Date): Observable<Array<any>> {
        const query = { selectedDate: WarningService.toLocalDate(currentDate)};

        return this.http.get<Array<any>>(`${this.baseAccountingUrl}/warnings/name/${nameKey}`, {
            params: new HttpParams().set('q', JSON.stringify(query))
        });
    }

    getCasenamesWarnings(caseKey: number, currentDate: Date): Observable<WipWarningData> {
        const query = { selectedDate: WarningService.toLocalDate(currentDate) };

        return this.http.get<WipWarningData>(`${this.baseAccountingUrl}/warnings/case/${caseKey}`, {
            params: new HttpParams().set('q', JSON.stringify(query))
        });
    }

    setPeriodTypeDescription(billingCapCheckResult: any): string {
        if (!!billingCapCheckResult) {
            switch (billingCapCheckResult.periodType.toLowerCase()) {
                case 'd':
                    return this.translate.instant('accounting.wip.warningMsgs.billingCap.periodConcatenation_Days', {
                        value: billingCapCheckResult.period.toString()
                    });
                case 'w':
                    return this.translate.instant('accounting.wip.warningMsgs.billingCap.periodConcatenation_Weeks', {
                        value: billingCapCheckResult.period.toString()
                    });
                case 'm':
                    return this.translate.instant('accounting.wip.warningMsgs.billingCap.periodConcatenation_Months', {
                        value: billingCapCheckResult.period.toString()
                    });
                case 'y':
                    return this.translate.instant('accounting.wip.warningMsgs.billingCap.periodConcatenation_Years', {
                        value: billingCapCheckResult.period.toString()
                    });
                default:
                    return null;
            }
        }
    }

    static toLocalDate(dateTime: Date): Date {
        if (dateTime instanceof Date) {
            return new Date(Date.UTC(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate()));
        }

        return null;
    }
}