import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AttachmentFileBrowserService {

  constructor(private readonly http: HttpClient) { }

  getDirectoryFolders = (path: string): Observable<any> => {

    const url = 'api/attachment/directory';

    return this.http.get(url, {
      params: {
        path
      }
    });
  };

  getDirectoryFiles = (path: string): Observable<any> => {

    if (!path) { return of([]); }

    const url = 'api/attachment/files';

    return this.http.get(url, {
      params: {
        path
      }
    });
  };
}
