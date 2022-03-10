import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class TimerModalService {
  private readonly baseTimeUrl = 'api/accounting/time';
  constructor(private readonly http: HttpClient) { }

  getDefaultNarrativeFromActivity = (activityKey: string, caseId?: number, nameId?: number, staffNameId?: number): Observable<any> => {
    return this.http.get(`${this.baseTimeUrl}/narrative`,
      {
        params:
        {
          activityKey,
          caseKey: caseId != null ? caseId.toString() : null,
          debtorKey: (caseId == null && nameId != null ? nameId.toString() : null),
          staffNameId: staffNameId != null ? staffNameId.toString() : null
        }
      });
  };
}
