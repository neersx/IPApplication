import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ReportExportFormat } from 'search/results/report-export.format';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

@Injectable()

export class SanityCheckResultsService {
  private readonly _apiBase = 'api/search/case/sanitycheck';
  constructor(private readonly http: HttpClient) { }

  getSanityCheckResults(processId: number, queryParams: GridQueryParameters): Observable<any> {
    return this.http.post('api/search/case/sanitycheck/results', { processId, params: queryParams });
  }
}