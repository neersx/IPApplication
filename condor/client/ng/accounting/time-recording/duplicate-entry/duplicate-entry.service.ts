import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { mergeMap, switchMap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class DuplicateEntryService {
  private readonly baseUrl = 'api/accounting/time/copy';
  private readonly requestDuplicate: Subject<number>;
  requestDuplicateOb$: Observable<number>;

  constructor(private readonly httpClient: HttpClient) {
    this.requestDuplicate = new Subject<number>();

    this.requestDuplicateOb$ = this.requestDuplicate
      .pipe(mergeMap((request: any) => this.httpClient.post<number>(this.baseUrl, request)));
  }

  initiateDuplicationRequest = (param: any): void => {
    this.requestDuplicate.next(param);
  };
}