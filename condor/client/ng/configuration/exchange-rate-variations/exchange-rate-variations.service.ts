import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { ExchangeRateVariationPermissions, ExchangeRateVariationRequest } from './exchange-rate-variations.model';

@Injectable()
export class ExchangeRateVariationService {
    constructor(private readonly http: HttpClient) { }
    url = 'api/configuration/exchange-rate-variation';
    navigationOptions: any;

    getViewData = (exchangeRateSchedule: string): Observable<ExchangeRateVariationPermissions> => {
        const type = typeof exchangeRateSchedule !== 'undefined' && exchangeRateSchedule ? 'EXS' : 'CUR';

        return this.http.get<ExchangeRateVariationPermissions>(this.url + '/permissions' + '/' + type);
    };

    getExchangeRateVariations = (criteria: any, queryParams: GridQueryParameters): Observable<Array<any>> => {

        return this.http.get<Array<any>>(this.url, {
            params: {
                q: JSON.stringify(criteria),
                params: JSON.stringify(queryParams)
            }
        });
    };

        deleteExchangeRateVariations(ids: Array<number>): Observable<any> {
        const exchangeRateVariationIds = { ids };

        return this.http.request('delete', this.url + '/delete', { body: exchangeRateVariationIds });
    }

    getExchangeRateDetails(id: number): any {
        return this.http.get(`${this.url}/${id}`);
    }

    submitExchangeRateVariations(data: ExchangeRateVariationRequest): Observable<any> {
        if (!data.id) {

            return this.http.post(this.url, data);
        }

        return this.http.put(this.url + '/' + data.id, data);
    }

    validateExchangeRateVariations(request: any): any {
        return this.http.post(`${this.url}/validate`, request);
    }

}
