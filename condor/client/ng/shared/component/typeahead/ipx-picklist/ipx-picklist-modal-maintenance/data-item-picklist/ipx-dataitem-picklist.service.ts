import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { DataItem } from './data-item-picklist.model';

@Injectable({
    providedIn: 'root'
})
export class IpxDataItemService {
    constructor(private readonly http: HttpClient) {

    }
    validateSql(params): Observable<any> {
        return this.http
            .post('api/configuration/dataitems/validate', params);
    }
}