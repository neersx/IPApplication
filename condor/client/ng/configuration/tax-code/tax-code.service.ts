import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject, Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { CommonSearchParams, GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { TaxCodes } from './tax-code.model';

@Injectable()
export class TaxCodeService {
  _baseUri = 'api/configuration/tax-codes';
  inUseTaxCode: Array<number> = [];
  _previousStateParam$ = new BehaviorSubject(null);
  selectedTopic: string;
  _taxCodeDescription$ = new BehaviorSubject(null);

  constructor(private readonly http: HttpClient, private readonly navigationService: GridNavigationService,
    private readonly localSettings: LocalSettings) {
    this.navigationService.init(this.searchMethod, 'id');
  }

  getTaxCodeViewData(): Observable<any> {
    return this.http
      .get<any>(this._baseUri + '/viewdata/')
      .pipe(map((response: any) => {
        return response;
      }));
  }

  markInUse = (resultSet) => {
    _.each(resultSet, (item: any) => {
      _.each(this.inUseTaxCode, (inUseId) => {
        if (item.id === inUseId) {
          item.inUse = true;
          item.persisted = false;
          item.selected = true;
        }
      });
    });
  };
  private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<any> => {
    const q: any = {
      criteria: lastSearch.criteria,
      params: lastSearch.params
    };

    return this.getTaxCodes(q.criteria, q.params);
  };

  setSelectedTopic(topicKey: string): void {
    this.selectedTopic = topicKey;
  }

  overviewDetails(id: number): Observable<any> {
    return this.http.get<any>(`${this._baseUri}/` + 'overview-details/' + id);
  }

  taxRatesDetails(id: number): Observable<any> {
    return this.http.get<any>(`${this._baseUri}/` + 'tax-rate-details/' + id).pipe(map((response: any) => {
      _.each(response, (item: any) => {
        item.effectiveDate = new Date(item.effectiveDate);
        item.taxRate = Number(item.taxRate);
      });

      return response;
    }));
  }

  getTaxCodes(searchCriteria: any, queryParams: any): Observable<any> {
    return this.http.get(this._baseUri + '/search', {
      params: {
        q: JSON.stringify(searchCriteria),
        params: JSON.stringify(queryParams)
      }
    }).pipe(map((res: any) => {
      this.localSettings.keys.navigation.searchCriteria.setLocal(searchCriteria);
      this.localSettings.keys.navigation.queryParams.setLocal(queryParams);
      this.localSettings.keys.navigation.ids.setLocal(res.ids);

      return res.taxCodes;
    }), this.navigationService.setNavigationData(searchCriteria, queryParams));
  }

  saveTaxCode(taxCodes: TaxCodes): Observable<any> {
    return this.http.post(`${this._baseUri}/` + 'create', taxCodes);
  }

  deleteTaxCodes = (ids: Array<number>) => {
    return this.http.post(`${this._baseUri}/` + 'delete', {
      ids
    });
  };

  updateTaxCodeDetails(taxCodeDetails: any): any {
    return this.http.post(`${this._baseUri}/` + 'update', taxCodeDetails);
  }
}