import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { CaseNavigationService, SearchResult } from 'cases/core/case-navigation.service';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { SelectedColumn } from 'search/presentation/search-presentation.model';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { SearchResultsViewData, StateParams } from './search-results.data';
import { SearchResultColumn } from './search-results.model';

export interface ISearchResultService {
  getSearchResultsViewData(
    params
  ): Observable<SearchResultsViewData>;
  getSearch$(filter, params: GridQueryParameters, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<SearchResult>;
  getColumns$(queryKey, selectedColumns: Array<SelectedColumn>, presentationType: string, queryContext: Number): Observable<Array<SearchResultColumn>>;
  getColumnFilterData(filter: any, column: any, params: any, queryKey: number, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<any>;
  getSavedSearch$(queryKey: number, params: any, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<any>;
  search$(filter, params: GridQueryParameters, selectedColumns: Array<SelectedColumn>, queryContext: Number, presentationType?: string): Observable<any>;
  getEditedSavedSearch$(queryKey, filter, params: GridQueryParameters, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<any>;
}

@Injectable({
  providedIn: 'root'
})

export class SearchResultsService implements ISearchResultService {
  rowSelected = new BehaviorSubject(null);
  private _previousState: StateParams;
  constructor(private readonly http: HttpClient, private readonly navigationService: CaseNavigationService) { }

  getSearch$(filter, params: GridQueryParameters, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<SearchResult> {
    return this.search$(filter, params, selectedColumns, queryContext)
      .pipe(
        this.navigationService.setNavigationData(filter, params, null, queryContext)
      );
  }

  getColumns$(queryKey, selectedColumns: Array<SelectedColumn>, presentationType: string, queryContext: Number): Observable<Array<SearchResultColumn>> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http.post<Array<SearchResultColumn>>(`${baseApiRoute}columns`, {
      queryKey,
      presentationType,
      selectedColumns,
      queryContext
    });
  }

  getEditedSavedSearch$(queryKey, filter, params: GridQueryParameters, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<any> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http.post(`${baseApiRoute}editedSavedSearch`, {
      queryKey,
      criteria: (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : filter,
      params,
      queryContext,
      selectedColumns
    });
  }

  getColumnFilterData(filter: any, column: any, params: any, queryKey: number, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<any> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http.post(`${baseApiRoute}filterData`, {
      criteria: (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : filter,
      params,
      column,
      queryKey,
      queryContext,
      selectedColumns
    });
  }

  search$(filter, params: GridQueryParameters, selectedColumns: Array<SelectedColumn>, queryContext: Number, presentationType?: string): Observable<any> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;
    const _filter = {
      criteria: (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : filter,
      params,
      queryContext,
      selectedColumns,
      presentationType
    };

    return this.http.post(baseApiRoute, _filter);
  }

  getSavedSearch$(queryKey: number, params: any, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<any> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http.post(
      `${baseApiRoute}savedSearch`, {
      queryKey,
      params,
      selectedColumns,
      queryContext
    }
    ).pipe(
      this.navigationService.setNavigationData(null, params, queryKey, queryContext)
    );
  }

  getSearchResultsViewData = (params: any): Observable<SearchResultsViewData> => {
    if (!params.queryContext) {

      return of(null);
    }

    const baseApiRoute = SearchTypeConfigProvider.getConfigurationConstants(+params.queryContext).baseApiRoute;

    return this.http
      .get(`${baseApiRoute}view?queryKey=${params.queryKey}&queryContext=${params.queryContext}`)
      .pipe(
        map((response: SearchResultsViewData) => {
          return {
            hasOffices: response.hasOffices,
            hasFileLocation: response.hasFileLocation,
            q: params.q,
            filter: params.filter,
            queryKey: params.queryKey,
            queryName: response.queryName,
            queryContext: response.queryContext,
            isExternal: response.isExternal,
            searchQueryKey: params.searchQueryKey,
            rowKey: params.rowKey,
            clearSelection: params.clearSelection,
            programs: response.programs,
            hasDueDatePresentation: params.hasDueDatePresentation,
            selectedColumns: params.selectedColumns,
            presentationType: params.queryKey === null ? params.presentationType : null,
            globalProcessKey: params.queryKey === null ? params.globalProcessKey : null,
            backgroundProcessResultTitle: params.queryKey === null ? params.backgroundProcessResultTitle : null,
            permissions: response.permissions,
            reportProviderInfo: response.reportProviderInfo,
            billingWorksheetTimeout: response.billingWorksheetTimeout,
            exportLimit: response.exportLimit,
            entities: response.entities
          };
        })
      );
  };

  get previousState(): StateParams {
    return this._previousState;
  }

  set previousState(value: StateParams) {
    this._previousState = { ...value };
  }
}
