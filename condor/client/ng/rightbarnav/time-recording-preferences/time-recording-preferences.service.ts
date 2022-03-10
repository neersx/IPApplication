import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class TimeRecordingPreferenceService {
    constructor(private readonly http: HttpClient) {

    }

    loadPreferences(): Observable<any> {
        return this.http.get('api/accounting/time/settings');
    }

    savePreferences(data: any): Observable<any> {
        return this.http.post('api/accounting/time/settings/update', data);
    }

    resetPreferences(): Observable<any> {
        return this.http.post('api/accounting/time/settings/reset', null);
    }
}