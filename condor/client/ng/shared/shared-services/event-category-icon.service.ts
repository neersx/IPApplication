import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class EventCategoryIconService {
    constructor(private readonly http: HttpClient) { }

    getEventCategoryIcon$(imageKey: number, maxWidth: number, maxHeight: number): Observable<any> {
        return this.http.get('api/shared/image/' + encodeURI(imageKey.toString()) + '/' + maxWidth + '/' + maxHeight);
    }
}
