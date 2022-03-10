import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { CommonSearchParams, GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { BulkOperationType, KeywordItems, KeywordsPermissions } from './keywords.model';

@Injectable()
export class KeywordsService {

  constructor(private readonly http: HttpClient, private readonly gridNavigationService: GridNavigationService) {
    this.gridNavigationService.init(this.searchMethod, 'keywordNo');
  }
  navigationOptions: any;
  url = 'api/configuration/keywords';

  getViewData = (): Observable<KeywordsPermissions> => {
    return this.http.get<KeywordsPermissions>(this.url + '/viewdata');
  };

  initNavigationOptions = (keyField) => {
    this.navigationOptions = {
      keyField
    };
    this.gridNavigationService.init(this.searchMethod, this.navigationOptions.keyField);
  };

  private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<any> => {
    const q: any = {
      criteria: lastSearch.criteria,
      params: lastSearch.params
    };

    return this.getKeywordsList(q.criteria, q.params);
  };

  getKeywordsList = (criteria: any, queryParams: GridQueryParameters): Observable<Array<KeywordItems>> => {

    return this.http.get<Array<KeywordItems>>(this.url, {
      params: {
        q: JSON.stringify(criteria),
        params: JSON.stringify(queryParams)
      }
    }).pipe(this.gridNavigationService.setNavigationData(criteria, queryParams));
  };

  submitKeyWord(data: KeywordItems): Observable<any> {
    if (!data.keywordNo) {

      return this.http.post(this.url, data);
    }

    return this.http.put(this.url + '/' + data.keywordNo, data);

  }

  getKeyWordDetails(keyWordNo: number): any {
    return this.http.get(`${this.url}/${keyWordNo}`);
  }

  performBulkOperation(selectedRowKeys: Array<string>, deSelectedRowKeys: Array<string>, isAllSelected: boolean, operationType: BulkOperationType): Observable<any> {
    const uri = 'api/keywords/' + operationType;

    return this.http.post(uri, {
      selectedRowKeys,
      deSelectedRowKeys,
      isAllSelected
    });
  }

  deleteKeywords(ids: Array<number>): Observable<any> {
    const officeIds = { ids };

    return this.http.request('delete', this.url + '/delete', { body: officeIds });
  }
}
