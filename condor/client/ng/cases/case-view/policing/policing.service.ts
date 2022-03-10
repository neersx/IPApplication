import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class PolicingService {
  readonly policingCompleted = new BehaviorSubject<boolean>(null);

  constructor(private readonly http: HttpClient) { }

  policeAction = (request: PoliceActionRequestModel): Promise<any> => {
    return this.http.post('api/cases/policeAction', request).toPromise().then(() => {
      if (request.isPoliceImmediately) {
        this.policingCompleted.next(true);
      }
    });
  };

  policeBatch = (batchNo: number): Promise<any> => {
    return this.http.post('api/cases/policeBatch', { batchNo }).toPromise();
  };
}

export class PoliceActionRequestModel {
  caseId: number;
  actionId: string;
  isPoliceImmediately: boolean;
}
