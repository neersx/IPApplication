import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { TimeEntry } from '../time-recording.namespace';

@Injectable()
export class AdjustValueService {

    timeUrl = 'api/accounting/time';
    constructor(private readonly http: HttpClient) { }

    previewCost(timeCost: TimeCost): Observable<any> {
        return this.http.post(`${this.timeUrl}/cost-preview`, timeCost);
    }

    saveAdjustedValues(timeEntry: TimeEntry): any {
        return this.http.put(`${this.timeUrl}/adjust-value`, timeEntry);
    }
}

export class TimeCost {
    nameKey?: number;
    caseKey?: number;
    wipCode?: string;
    localValueBeforeMargin?: number;
    foreignValueBeforeMargin?: number;
    localValue?: number;
    foreignValue?: number;
    localMargin?: number;
    foreignMargin?: number;
    localDiscount?: number;
    foreignDiscount?: number;
    localDiscountBeforeMargin?: number;
    foreignDiscountBeforeMargin?: number;
    currencyCode?: string;
    exchangeRate?: number;
    timeUnits?: number;
    entryNo: number;
    marginNo?: number;
    staffKey?: number;
}