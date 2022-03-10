import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BulkOperationType } from 'configuration/keywords/keywords.model';
import { Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { CommonSearchParams, GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { CurrencyItems, CurrencyPermissions, CurrencyRequest } from './currencies.model';

@Injectable()
export class CurrenciesService {
    constructor(private readonly http: HttpClient, private readonly gridNavigationService: GridNavigationService) {
        this.gridNavigationService.init(this.searchMethod, 'id');
    }
    url = 'api/configuration/currencies';
    navigationOptions: any;

    getViewData = (): Observable<CurrencyPermissions> => {
        return this.http.get<CurrencyPermissions>(this.url + '/viewdata');
    };

    getCurrencies = (criteria: any, queryParams: GridQueryParameters): Observable<Array<CurrencyItems>> => {

        return this.http.get<Array<CurrencyItems>>(this.url, {
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

        return this.getCurrencies(q.criteria, q.params);
    };

    initNavigationOptions = (keyField) => {
        this.navigationOptions = {
            keyField
        };
        this.gridNavigationService.init(this.searchMethod, this.navigationOptions.keyField);
    };

    deleteCurrencies(ids: Array<string>): Observable<any> {
        const officeIds = { ids };

        return this.http.request('delete', this.url + '/delete', { body: officeIds });
    }

    getCurrencyDetails(code: string): any {
        return this.http.get(`${this.url}/${code}`);
    }

    validateCurrencyCode(code: string): any {
        return this.http.get(`${this.url}/validate/${code}`);
    }

    performBulkOperation(selectedRowKeys: Array<string>, deSelectedRowKeys: Array<string>, isAllSelected: boolean, operationType: BulkOperationType): Observable<any> {
        const uri = 'api/currencies/' + operationType;

        return this.http.post(uri, {
            selectedRowKeys,
            deSelectedRowKeys,
            isAllSelected
        });
    }

    submitCurrency(data: CurrencyRequest): Observable<any> {
        if (!data.id) {
            data.id = data.currencyCode;

            return this.http.post(this.url, data);
        }

        return this.http.put(this.url + '/' + data.id, data);

    }

    getHistory = (id: string, queryParams: GridQueryParameters): Observable<any> => {
        return this.http.get(this.url + '/history/' + id, {
            params: {
                params: JSON.stringify(queryParams)
            }
        });
    };

    getCurrencyDesc = (id: string): Observable<string> => {
        return this.http.get<string>(this.url + '/currency-desc/' + id);
    };
}
