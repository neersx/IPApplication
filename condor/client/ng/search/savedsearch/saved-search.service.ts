import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SearchTypeConfig } from '../common/search-type-config.provider';
import { SaveOperationType, SaveSearchEntity } from './saved-search.model';
@Injectable()
export class SavedSearchService {
    constructor(private readonly http: HttpClient) { }

    getDetails$(queryKey: Number, config: SearchTypeConfig): Observable<any> {
        return this.http.get(`${config.baseApiRoute}get/` + encodeURI(queryKey.toString()));
    }

    saveSearch(saveSearchEntity: SaveSearchEntity, saveOperationType: SaveOperationType, queryKey: Number, config: SearchTypeConfig): Observable<any> {
        switch (saveOperationType) {
            case SaveOperationType.Add:
                return this.http.post(`${config.baseApiRoute}add/`, saveSearchEntity);
            case SaveOperationType.EditDetails:
                return this.http.put(`${config.baseApiRoute}updateDetails/` + queryKey.toString(), saveSearchEntity);
            case SaveOperationType.SaveAs:
                return this.http.post(`${config.baseApiRoute}saveAs/` + queryKey.toString(), saveSearchEntity);
            case SaveOperationType.Update:
                return this.http.put(`${config.baseApiRoute}update/` + queryKey.toString(), saveSearchEntity);
            default:
                throw new Error('Operation not determined.');
        }
    }
}
