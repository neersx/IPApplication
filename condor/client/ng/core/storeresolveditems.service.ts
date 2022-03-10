import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class StoreResolvedItemsService {

  baseUrl = 'api/storeresolveditems/';
  constructor(readonly http: HttpClient) { }

  add = (items: string): Observable<any> => {
    return this.http.post(this.baseUrl + 'add', { Items: items });
  };

}
