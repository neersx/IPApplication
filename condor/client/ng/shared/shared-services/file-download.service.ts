import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class FileDownloadService {

  constructor(private readonly http: HttpClient) { }

  downloadFile = (url: string, body: any): void => {
    this.http.post(
      url,
      body,
      {
        observe: 'response',
        responseType: 'arraybuffer'
      }).subscribe((response: any) => {
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
      });
  };
}
