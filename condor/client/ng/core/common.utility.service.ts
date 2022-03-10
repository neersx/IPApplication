import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { WindowRef } from './window-ref';

@Injectable()
export class CommonUtilityService {

  constructor(private readonly windowRef: WindowRef, private readonly http: HttpClient) { }

  formatString = (str: string, ...val: Array<string>): string => {
    let replacedStr = str;
    for (let index = 0; index < val.length; index++) {
      replacedStr = replacedStr.replace(`{${index}}`, val[index]);
    }

    return replacedStr;
  };

  getTimeOnlyFormat = (): string => {
    return 'hh:mm:ss a';
  };

  getBasePath = (): string => {
    const window = this.windowRef.nativeWindow;

    return this.formatString('{0}{1}', window.location.origin, window.location.pathname);
  };

  export = (exportUrl: string, exportRequest: any) => {
    this.http.post(exportUrl, exportRequest, {
      observe: 'response', responseType: 'arraybuffer'
    }).subscribe((response: any) => {
      this.handleExportResponse(response);
    });
  };

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