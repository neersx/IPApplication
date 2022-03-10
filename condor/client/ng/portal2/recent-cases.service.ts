import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { CaseNavigationService } from 'cases/core/case-navigation.service';
import { Observable } from 'rxjs';
import { SearchResult } from 'search/results/search-results.model';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

@Injectable({
  providedIn: 'root'
})
export class RecentCasesService {

  constructor(private readonly navigationService: CaseNavigationService, private readonly http: HttpClient) { }
  get = (queryParams: GridQueryParameters): Observable<SearchResult> => {
    this.navigationService.clearLoadedData();

    return this.http.get('api/recentCases', {
      params: new HttpParams().set('params', JSON.stringify(queryParams))
    }).pipe(
      this.navigationService.setNavigationData(null, {
        skip: null,
        take: null,
        filters: null
      })
    );
  };

  getDefaultProgram = (): Observable<string> => {
    return this.http.get<string>('api/recentCases/defaultProgram');
  };
}
