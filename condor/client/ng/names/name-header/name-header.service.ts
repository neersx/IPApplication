import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class NameHeaderService {
  constructor(readonly http: HttpClient) { }
  getHeader = (nameKey: number): Promise<any> => {
    return this.http.get(`api/name/${nameKey}/header`).toPromise();
  };
}
