import { Observable, of } from 'rxjs';

export class CaseViewActionsServiceMock {
    getViewData$ = jest.fn();
    getActions$: (caseKey: number, importanceLevel: number, includeOpenActions: boolean, includeClosedActions: boolean,
        includePotentialActions: boolean, queryParams: any) => jest.Mock = jest.fn();
    getActionEvents$: (caseKey: number, actionId: string, cycle: number, criteriaId: number, importanceLevel: number,
        isCyclic: boolean, queryParams: any, isAllEvents?: boolean, isMostRecentCycle?: boolean) => Observable<jest.Mock> = jest.fn();
    siteControlId = jest.fn().mockReturnValue(new Observable());
}