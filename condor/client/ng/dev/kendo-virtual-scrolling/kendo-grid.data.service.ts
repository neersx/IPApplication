import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class KendoGridDataService {

    constructor(private readonly http: HttpClient) {

    }

    runFullSearch(request: any, queryParams: any): Observable<any> {
        return this.http.get<any>('api/picklists/Tasks/Searchfull', {
        params: {
            q: JSON.stringify(request),
            params: JSON.stringify(queryParams)
        }
      });
    }
}
