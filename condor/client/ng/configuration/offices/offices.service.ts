import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { CommonSearchParams, GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { OfficeData, OfficeItems, OfficePermissions } from './offices.model';

@Injectable({
    providedIn: 'root'
})
export class OfficeService {
    constructor(private readonly http: HttpClient, private readonly gridNavigationService: GridNavigationService) {
        this.gridNavigationService.init(this.searchMethod, 'key');
    }
    url = 'api/configuration/offices';
    navigationOptions: any;

    getViewData = (): Observable<OfficePermissions> => {
        return this.http.get<OfficePermissions>(this.url + '/viewdata');
    };

    getOffices = (criteria: any, queryParams: GridQueryParameters): Observable<Array<OfficeItems>> => {

        return this.http.get<Array<OfficeItems>>(this.url, {
            params: {
                q: JSON.stringify(criteria),
                params: JSON.stringify(queryParams)
            }
        }).pipe(this.gridNavigationService.setNavigationData(criteria, queryParams));
    };

    getRegions = (): Observable<Array<any>> => {

        return this.http.get<Array<any>>('api/picklists/tablecodes?tableType=139');
    };

    getPrinters = (): Observable<Array<any>> => {

        return this.http.get<Array<any>>(this.url + '/printers');
    };

    getOffice = (id: number): Observable<OfficeData> => {

        return this.http.get<OfficeData>(this.url + '/' + id);
    };

    private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<any> => {
        const q: any = {
            criteria: lastSearch.criteria,
            params: lastSearch.params
        };

        return this.getOffices(q.criteria, q.params);
    };

    initNavigationOptions = (keyField) => {
        this.navigationOptions = {
            keyField
        };
        this.gridNavigationService.init(this.searchMethod, this.navigationOptions.keyField);
    };

    deleteOffices(ids: Array<number>): Observable<any> {
        const officeIds = { ids };

        return this.http.request('delete', this.url + '/delete', { body: officeIds });
    }

    saveOffice(data: OfficeData): Observable<any> {
        if (data.id === null) {
            delete data.id;

            return this.http.post(this.url, data);
        }

        return this.http.put(this.url + '/' + data.id, data);
    }
}
