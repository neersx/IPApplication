import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { CaseNavigationService } from 'cases/core/case-navigation.service';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { SelectedColumn } from '../presentation/search-presentation.model';
import {
  CaseSavedSearchData,
  CaseSearchData,
  CaseSearchViewData,
  CaseStateParams
} from './case-search.data';

export interface ICaseSearchService {
  caseSearchData: CaseSearchData;
  getCaseSearchViewData(returnFromCaseResults: Boolean): Observable<CaseSearchViewData>;
  getCaseSavedSearchData(params: any): Observable<CaseSavedSearchData>;
  getCaseSummary(caseKey: number): Observable<any>;
  getGlobalCaseChangeResults$(globalProcessKey: number, searchPresentationType: string, params: GridQueryParameters, queryContext?: Number): Observable<any>;
  getDueDateSavedSearch$(queryKey, filter, params: GridQueryParameters, queryContext?: Number): Observable<any>;
  getBatchEventUpdateUrl(caseIds: string): Observable<any>;
  caseIdsForBulkOperations$(filter: any, queryContext: number, queryKey: number, deselectedIds: any): Observable<Array<Number>>;
}

@Injectable()
export class CaseSearchService implements ICaseSearchService {
  rowSelected = new BehaviorSubject(null);
  private _caseSearchData: CaseSearchData;
  private _previousState: CaseStateParams;

  constructor(
    private readonly http: HttpClient,
    private readonly navigationService: CaseNavigationService
  ) { }

  getCaseSummary(caseKey: number): Observable<any> {
    return this.http
      .get('api/search/case/' + encodeURI(caseKey.toString()) + '/searchsummary');
  }

  getCaseSearchViewData(params: any): Observable<CaseSearchViewData> {
    if (params.returnFromCaseSearchResults && this._caseSearchData) {
      return of(this._caseSearchData.viewData);
    }

    const queryKey = params.queryKey;

    return this.http.get('api/search/case/casesearch/view/' + queryKey).pipe(
      map((response: CaseSearchViewData) => {
        return response;
      })
    );
  }

  getCaseSavedSearchData(params: any): Observable<CaseSavedSearchData> {
    if (params.returnFromCaseSearchResults && this._caseSearchData) {
      return of(this._caseSearchData.savedSearchData);
    }

    const queryKey = +params.queryKey;
    if (queryKey && params.canEdit) {
      return this.http.get('api/search/case/casesearch/builder/' + queryKey).pipe(
        map((response: CaseSavedSearchData) => {

          return {
            queryKey,
            queryName: response.queryName,
            steps: response.steps,
            dueDateFormData: response.dueDateFormData,
            isPublic: response.isPublic,
            queryContext: response.queryContext
          };
        })
      );
    }

    return null;
  }

  set caseSearchData(value: CaseSearchData) {
    this._caseSearchData = { ...value };
  }

  get caseSearchData(): CaseSearchData {
    return this._caseSearchData;
  }

  getBatchEventUpdateUrl(caseIds: string): Observable<any> {
    return this.http.post('api/BatchEventUpdate/BatchEvent', {
      caseIds
    });
  }

  applySanityCheck(caseIds: Array<number>): Observable<any> {
    return this.http.post('api/search/case/sanitycheck/apply', caseIds);
  }

  DeletePresentation(queryKey): any {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;
    if (queryKey) {
      return this.http
        .get(`${baseApiRoute}deleteSavedSearch/${queryKey}`)
        .pipe(
          map((response: any) => {
            return response;
          }));
    }
  }

  getNameVariants(nameId: any): any {
    return this.http
      .get('api/lists/namevariant?nameId=' + nameId)
      .toPromise()
      .then((response: any) => {
        return response;
      });
  }

  getCaseEditedSavedSearch$(queryKey, filter, params: GridQueryParameters, selectedColumns: Array<SelectedColumn>, queryContext?: Number): Observable<any> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http.post(`${baseApiRoute}editedSavedSearch`, {
      queryKey,
      criteria: (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : filter,
      params,
      queryContext,
      selectedColumns
    });
  }

  getGlobalCaseChangeResults$(globalProcessKey: number, presentationType: string, params: GridQueryParameters, queryContext?: Number): Observable<any> {

    return this.http.post('api/globalCaseChangeResults', {
      globalProcessKey,
      presentationType,
      params,
      searchName: '',
      queryContext
    });
  }

  getDueDateSavedSearch$(queryKey, filter, params: GridQueryParameters, queryContext?: Number): Observable<any> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http.post(`${baseApiRoute}dueDateSavedSearch`, {
      queryKey,
      criteria: filter,
      params,
      queryContext
    });
  }

  caseIdsForBulkOperations$(filter: any, queryContext: number, queryKey: number, deselectedIds: any): Observable<Array<Number>> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http
      .post<Array<number>>(
        `${baseApiRoute}caseIds`, {
        criteria: (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : filter,
        queryKey,
        queryContext,
        deselectedIds
      });
  }

  get previousState(): CaseStateParams {
    return this._previousState;
  }

  set previousState(value: CaseStateParams) {
    this._previousState = { ...value };
  }
}
