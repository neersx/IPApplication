import { HttpClient, HttpResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { SelectedColumn } from 'search/presentation/search-presentation.model';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { ReportExportFormat } from './report-export.format';

export interface ISearchExportService {
  exportGlobalChangeResultToExcel(
    globalProcessKey: number,
    searchPresentationType: string,
    params: GridQueryParameters,
    searchName: string,
    exportFormat: ReportExportFormat
  ): void;
}

@Injectable()
export class SearchExportService implements ISearchExportService {

  private readonly _apiGenerateContentId = 'api/export/content';

  constructor(private readonly http: HttpClient) { }

  exportGlobalChangeResultToExcel(globalProcessKey: number,
    presentationType: string,
    params: GridQueryParameters,
    searchName: string,
    exportFormat: ReportExportFormat): void {
    this.http
      .post(
        'api/globalCaseChangeResults/export',
        {
          globalProcessKey,
          presentationType,
          params,
          searchName,
          exportFormat
        },
        {
          observe: 'response',
          responseType: 'arraybuffer'
        }
      )
      .subscribe((response: any) => {
        this.handleExportResponse(response);
      });
  }

  generateContentId(connectionId: string): Observable<number> {
    return this.http.get<number>(this._apiGenerateContentId + '/' + connectionId);
  }

  removeAllContents(connectionId: string): Observable<any> {
    return this.http.post(this._apiGenerateContentId + '/remove/' + connectionId, null);
  }

  export(filter: any, params: any, searchName: any, queryKey: any, queryContext: number,
     forceConstructXmlCriteria: any, selectedColumns: Array<SelectedColumn>,
     exportFormat: ReportExportFormat, contentId: number, deselectedIds?: any): Observable<any> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http
      .post(
        `${baseApiRoute}export`,
        {
          criteria: (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : filter,
          params,
          searchName,
          queryKey,
          queryContext,
          forceConstructXmlCriteria,
          selectedColumns,
          deselectedIds,
          exportFormat,
          contentId
        }
      );
  }

  exportToCpaXml(filter: any, queryContext: number): Observable<any> {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

    return this.http
      .post(
        `${baseApiRoute}exportToCpaXml`, {
        criteria: (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : filter,
        queryContext
      }, {
        observe: 'response'
      });
  }

  private readonly handleExportResponse = (response: any): void => {
    const headers = response.headers;
    const data: any = response.body;

    const filename = headers.get('x-filename');
    const contentType = headers.get('content-type');

    const blob = new Blob([data], { type: contentType });

    if (window.Blob && window.navigator.msSaveOrOpenBlob) {
      // for IE browser
      window.navigator.msSaveOrOpenBlob(blob, filename);
    } else {
      // for other browsers
      const linkElement = document.createElement('a');

      const fileURL = window.URL.createObjectURL(blob);
      linkElement.href = fileURL;
      linkElement.download = filename;
      linkElement.click();
    }
  };
}