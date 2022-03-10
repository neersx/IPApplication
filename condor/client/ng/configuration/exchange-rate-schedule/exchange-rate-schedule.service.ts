import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { CommonSearchParams, GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { ExchangeRateScheduleItems, ExchangeRateSchedulePermissions, ExchangeRateScheduleRequest } from './exchange-rate-schedule.model';

@Injectable()
export class ExchangeRateScheduleService {
    constructor(private readonly http: HttpClient, private readonly gridNavigationService: GridNavigationService) {
        this.gridNavigationService.init(this.searchMethod, 'id');
    }
    url = 'api/configuration/exchange-rate-schedule';
    navigationOptions: any;

    getViewData = (): Observable<ExchangeRateSchedulePermissions> => {
        return this.http.get<ExchangeRateSchedulePermissions>(this.url + '/viewdata');
    };

    getExchangeRateSchedule = (criteria: any, queryParams: GridQueryParameters): Observable<Array<ExchangeRateScheduleItems>> => {

        return this.http.get<Array<ExchangeRateScheduleItems>>(this.url, {
            params: {
                q: JSON.stringify(criteria),
                params: JSON.stringify(queryParams)
            }
        }).pipe(this.gridNavigationService.setNavigationData(criteria, queryParams));
    };

    private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<any> => {
        const q: any = {
            criteria: lastSearch.criteria,
            params: lastSearch.params
        };

        return this.getExchangeRateSchedule(q.criteria, q.params);
    };

    initNavigationOptions = (keyField) => {
        this.navigationOptions = {
            keyField
        };
        this.gridNavigationService.init(this.searchMethod, this.navigationOptions.keyField);
    };

    getExchangeRateScheduleDetails(id: number): any {
        return this.http.get(`${this.url}/${id}`);
    }

    validateExchangeRateScheduleCode(code: string): any {
        return this.http.get(`${this.url}/validate/${code}`);
    }

    submitExchangeRateSchedule(data: ExchangeRateScheduleRequest): Observable<any> {
        if (!data.id) {
            data.id = data.id;

            return this.http.post(this.url, data);
        }

        return this.http.put(this.url + '/' + data.id, data);
    }

    deleteExchangeRateSchedules(ids: Array<string>): Observable<any> {
        const exchRateScheduleIds = { ids };

        return this.http.request('delete', this.url + '/delete', { body: exchRateScheduleIds });
    }
}
