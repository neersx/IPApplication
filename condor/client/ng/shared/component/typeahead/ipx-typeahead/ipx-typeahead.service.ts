import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, pipe } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class IpxTypeaheadService {

  maxResults = 30;

  selectedItem = {
    value: '',
    key: '',
    selected: false
  };

  constructor(private readonly httpClient: HttpClient) { }

  getApiData(apiUrl: any, params: any): Observable<any> {
    return this.httpClient.get(apiUrl, {
      params
    }).pipe(map(response => response));
  }

}
