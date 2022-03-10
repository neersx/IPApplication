import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { CommonSearchParams, GridNavigationService, SearchResult } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { Columns, QueryColumnViewData, SearchColumnSaveDetails, SearchCriteria } from './search-columns.model';

@Injectable()
export class SearchColumnsService {
  _baseUri = 'api/search/columns';
  savedSearchColumns: Array<number> = [];
  inUseSearchColumns: Array<number> = [];
  constructor(private readonly http: HttpClient, private readonly navigationService: GridNavigationService) {
     this.navigationService.init(this.searchMethod, 'columnId');
   }

  private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<SearchResult> => {
    const q: any = {
      criteria: lastSearch.criteria,
      params: lastSearch.params
    };

    return this.getSearchColumns(q.criteria, q.params);
  };

  getColumnsViewData(params): Observable<QueryColumnViewData> {
    return this.http
      .get<QueryColumnViewData>(this._baseUri + '/viewdata/' + params.queryContextKey)
      .pipe(map((response: any) => {
        return response;
      }));
  }

  getSearchColumns(searchCriteria: SearchCriteria, queryParams: any): Observable<any> {
    return this.http.get(this._baseUri + '/search', {
      params: {
        searchOption: JSON.stringify(searchCriteria),
        queryParams: JSON.stringify(queryParams)
      }
    }).pipe(this.navigationService.setNavigationData(searchCriteria, queryParams));
  }

  searchColumnUsage(columnKey: number): Observable<Array<any>> {
    return this.http.get<Array<any>>(this._baseUri + '/usage/' + columnKey);
  }

  searchColumn(queryContextKey: number, columnKey: number): Observable<SearchColumnSaveDetails> {
    return this.http.get<SearchColumnSaveDetails>(this._baseUri + '/context/' + queryContextKey + '/' + columnKey);
  }

  saveSearchColumn(searchColumnSaveDetails: SearchColumnSaveDetails): Observable<any> {
    return this.http.post(this._baseUri, searchColumnSaveDetails);
  }

  updateSearchColumn(searchColumnSaveDetails: SearchColumnSaveDetails): Observable<any> {
    return this.http.put(this._baseUri + '/' + searchColumnSaveDetails.columnId, searchColumnSaveDetails);
  }

  persistSavedSearchColumns = (dataSource) => {
    _.each(dataSource, (searchColumn: any) => {
      _.each(this.savedSearchColumns, (savedColumnId) => {
        if (searchColumn.columnId === savedColumnId) {
          searchColumn.persisted = true;
        }
      });
    });
  };

  markInUseSearchColumns = (resultSet) => {
    _.each(resultSet, (searchColumn: any) => {
        _.each(this.inUseSearchColumns, (inUseId) => {
            if (searchColumn.columnId === inUseId) {
                searchColumn.inUse = true;
                searchColumn.persisted = false;
                searchColumn.selected = true;
            }
        });
    });
  };

  deleteSearchColumns = (ids: Array<number>, contextId: Number) => {
    return this.http.post(this._baseUri + '/delete', {
        ids,
        contextId
    });
  };
}
