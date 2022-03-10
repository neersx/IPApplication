import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class PropertyIconService {
    constructor(private readonly http: HttpClient) { }

    getPropertyTypeIcon$(imageKey: Number): Observable<any> {
        return this.http.get('api/shared/image/' + encodeURI(imageKey.toString()) + '/20/20');
    }
}
