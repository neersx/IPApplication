import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class PingService {

  constructor(private readonly http: HttpClient) { }

  ping = (): Promise<any> => {
    return this.http.put('api/signin/ping', {}).toPromise();
  };
}
