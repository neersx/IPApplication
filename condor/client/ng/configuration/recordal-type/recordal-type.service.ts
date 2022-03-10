import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { RecordalTypeItems, RecordalTypePermissions, RecordalTypeRequest } from './recordal-type.model';

@Injectable({
    providedIn: 'root'
})
export class RecordalTypeService {
    constructor(private readonly http: HttpClient) {
    }
    url = 'api/configuration/recordaltypes';
    isAddAnotherChecked = new BehaviorSubject<boolean>(false);
    getViewData = (): Observable<RecordalTypePermissions> => {
        return this.http.get<RecordalTypePermissions>(this.url + '/viewdata');
    };

    getRecordalType = (criteria: any, queryParams: GridQueryParameters): Observable<Array<RecordalTypeItems>> => {
        return this.http.get<Array<RecordalTypeItems>>(this.url, {
            params: {
                q: JSON.stringify(criteria),
                params: JSON.stringify(queryParams)
            }
        });
    };

    deleteRecordalType(id: number): Observable<any> {
        return this.http.request('delete', this.url + '/delete/' + id);
    }

    getRecordalTypeFormData(id: number): Observable<any> {
        return this.http.get(`${this.url}/${id}`);
    }

    getRecordalElementFormData(id: number): Observable<any> {
        return this.http.get(`${this.url}/element/${id}`);
    }

    getAllElements(): any {
        return this.http.get(`${this.url}/elements/`);
    }

    submitRecordalType(request: RecordalTypeRequest): any {
        return this.http.post(`${this.url}/submit/`, request);
    }
}
