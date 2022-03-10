import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { ValidationError } from 'shared/component/forms/validation-error';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { DesignElementItems } from './design-elements.model';

@Injectable({
  providedIn: 'root'
})
export class DesignElementsService {
  private readonly hasPendingChangesSubject = new BehaviorSubject<boolean>(false);
  private readonly hasErrorsSubject = new BehaviorSubject<boolean>(false);
  isAddAnotherChecked = new BehaviorSubject<boolean>(false);
  hasPendingChanges$ = this.hasPendingChangesSubject.asObservable();
  hasErrors$ = this.hasErrorsSubject.asObservable();

  states = {
    hasPendingChanges: undefined,
    hasErrors: undefined
  };
  constructor(private readonly http: HttpClient) {
  }

  getDesignElements = (caseKey: number, queryParams: GridQueryParameters): Observable<Array<DesignElementItems>> => {
    return this.http.get<Array<DesignElementItems>>(`api/case/${caseKey}/designElements`, {
      params: {
        params: JSON.stringify(queryParams)
      }
    });
  };

  getValidationErrors = (caseKey: number, currentRow: DesignElementItems, changedRows: Array<DesignElementItems>): Observable<Array<ValidationError>> => {
    return this.http.post<Array<ValidationError>>('api/case/designElements/validate', {
      caseKey,
      currentRow,
      changedRows
    });
  };

  raisePendingChanges = (hasPendingChanges: boolean) => {
    if (hasPendingChanges !== this.states.hasPendingChanges) {
      this.states.hasPendingChanges = hasPendingChanges;
      this.hasPendingChangesSubject.next(hasPendingChanges);
    }
  };

  raiseHasErrors = (hasErrors: boolean) => {
    if (hasErrors !== this.states.hasErrors) {
      this.states.hasErrors = hasErrors;
      this.hasErrorsSubject.next(hasErrors);
    }
  };
}
