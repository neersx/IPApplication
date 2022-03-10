import { Observable } from 'rxjs';

export class CaseViewEventsServiceMock {
    getCaseViewOccurredEvents: (caseKey: number, importanceLevel: number, queryParams: any) => jest.Mock = jest.fn();
    getCaseViewDueEvents: (caseKey: number, importanceLevel: number, queryParams: any) => Observable<jest.Mock> = jest.fn();
    siteControlId = jest.fn().mockReturnValue(new Observable());
}