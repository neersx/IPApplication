import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ScreenDesignerService {

  constructor(private readonly http: HttpClient) {
  }
  private readonly states: Array<StateCriteriaIdModel> = [];
  getCriteriaSearchViewData$(): Observable<ScreenDesignerViewData> {
    return this.http.get<ScreenDesignerViewData>('api/configuration/rules/screen-designer/case/viewData');
  }

  getCriteriaMaintenanceViewData$(id: number): Observable<ScreenDesignerCriteriaViewData> {
    return this.http.get<ScreenDesignerCriteriaViewData>(`api/configuration/rules/screen-designer/case/${id}`);
  }

  getCriteriaDetails$(id: number): Observable<ScreenDesignerCriteriaDetails> {
    return this.http.get<ScreenDesignerCriteriaDetails>(`api/configuration/rules/screen-designer/case/${id}/characteristics`);
  }

  getCriteriaSections$ = (criteria: number): Observable<any> => {
    return this.http.get(`api/configuration/rules/screen-designer/case/${criteria}/sections`);
  };

  previousState(): string {
    return this.states.length !== 0 && this.states[this.states.length - 1].stateName;
  }

  pushState(state: StateCriteriaIdModel): void {
    this.states.push(state);
  }

  popState(): StateCriteriaIdModel {
    return this.states.pop();
  }
}

export class StateCriteriaIdModel {
  id: number;
  stateName: string;
}

export class ScreenDesignerViewData {
  canMaintainProtectedRules: boolean;
  canMaintainRules: boolean;
  hasOffices: boolean;
}

export class ScreenDesignerCriteriaViewData {
  canEdit: boolean;
  editBlockedByDescendants: boolean;
  canEditProtected: boolean;
  hasOffices: boolean;
  criteriaId: number;
  criteriaName: string;
  isProtected: boolean;
  isInherited: boolean;
  isHighestParent: boolean;
}

export class ScreenDesignerCriteriaDetails {
  id: number;
  criteriaName: string;
  office: any;
  program: any;
  caseType: any;
  caseCategory: any;
  jurisdiction: any;
  subType: any;
  propertyType: any;
  basis: any;
  isProtected: boolean;
}
