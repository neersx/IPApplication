import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { KotFilterCriteria, KotFilterTypeEnum, KotPermissionsType, KotTextType, KotTextTypesItems } from './kot-text-types.model';

@Injectable({
    providedIn: 'root'
})
export class KotTextTypesService {
    constructor(private readonly http: HttpClient) {
    }

    caseUrl = 'api/configuration/kottexttypes/case';
    nameUrl = 'api/configuration/kottexttypes/name';

    getKotTextTypes = (criteria: KotFilterCriteria, queryParams: GridQueryParameters): Observable<Array<KotTextTypesItems>> => {
        const url = criteria.type === KotFilterTypeEnum.byCase ? this.caseUrl : this.nameUrl;

        return this.http.get<Array<KotTextTypesItems>>(url, {
            params: {
                q: JSON.stringify(criteria),
                params: JSON.stringify(queryParams)
            }
        });
    };

    getKotTextTypeDetails = (id: number, filterBy: string): Observable<KotTextType> => {
        const url = filterBy === KotFilterTypeEnum.byCase ? this.caseUrl : this.nameUrl;

        return this.http.get<KotTextType>(url + '/' + id);
    };

    saveKotTextType(data: KotTextType, filterBy: string): Observable<any> {
        const url = filterBy === KotFilterTypeEnum.byCase ? this.caseUrl : this.nameUrl;

        return this.http.post(url + '/save', data);
    }

    getKotPermissions = (): Observable<KotPermissionsType> => {

        return this.http.get(this.caseUrl + '/permissions/')
            .pipe(
                map((response: KotPermissionsType) => {
                    return {
                        maintainKeepOnTopNotesCaseType: response.maintainKeepOnTopNotesCaseType,
                        maintainKeepOnTopNotesNameType: response.maintainKeepOnTopNotesNameType
                    };
                })
            );
    };

    deleteKotTextType(id: number, filterBy: string): Observable<any> {
        const url = filterBy === KotFilterTypeEnum.byCase ? this.caseUrl : this.nameUrl;

        return this.http.request('delete', url + '/delete/' + id);
    }
}
