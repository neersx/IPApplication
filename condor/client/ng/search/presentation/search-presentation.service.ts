import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { SaveSearchEntity } from 'search/savedsearch/saved-search.model';
import { PresentationColumnView, SearchPresentationViewData, SelectedColumn } from './search-presentation.model';

@Injectable()
export class SearchPresentationService {
  constructor(private readonly http: HttpClient) { }

  getAvailableColumns(queryContextKey): Observable<Array<PresentationColumnView>> {
    return this.http
      .get<Array<PresentationColumnView>>('api/search/presentation/available/' + queryContextKey);
  }

  getSelectedColumns(queryKey, queryContextKey): Observable<Array<PresentationColumnView>> {
    return this.http
      .get<Array<PresentationColumnView>>('api/search/presentation/selected/' + queryContextKey + '/' + ((queryKey === undefined || queryKey === '') ? null : queryKey));
  }

  revertToDefault(queryContextKey): any {
    return this.http.put('api/search/presentation/revertToDefault/' + queryContextKey, {});
  }

  makeMyDefaultPresentation(saveSearchEntity: SaveSearchEntity): any {
    return this.http.put('api/search/presentation/makeMyDefaultPresentation', saveSearchEntity);
  }

  getPresentationViewData(params): Observable<SearchPresentationViewData> {
    return this.http
      .get('api/search/view/' + params.queryContextKey)
      .pipe(map((response: any) => {
        return {
          isPublic: params.isPublic,
          isExternal: response.isExternal,
          filter: params.filter,
          queryKey: params.queryKey,
          queryName: params.queryName,
          q: params.q,
          queryContextKey: params.queryContextKey,
          importanceOptions: response.importanceOptions,
          canCreateSavedSearch: response.canCreateSavedSearch,
          canUpdateSavedSearch: response.canUpdateSavedSearch,
          canMaintainPublicSearch: response.canMaintainPublicSearch,
          userHasDefaultPresentation: response.userHasDefaultPresentation,
          canDeleteSavedSearch: response.canDeleteSavedSearch,
          canMaintainColumns: response.canMaintainColumns
        };
      })
      );
  }

  getDueDateSavedSearch(queryKey: Number): any {
    return this.http
      .get('api/search/case/casesearch/builder/' + queryKey);
  }
}