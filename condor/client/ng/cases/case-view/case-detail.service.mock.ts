import { BehaviorSubject, Observable, Subject } from 'rxjs';
import { ValidationError } from 'shared/component/forms/validation-error';
import { IppAvailability } from './case-detail.service';
import { CaseViewViewData } from './view-data.model';
export class CaseDetailServiceMock {
    getOverview$: (id: any, rowKey: Number) => Observable<any> = jest.fn();
    getIppAvailability$: (id: Number) => Observable<IppAvailability> = jest.fn();
    getCaseWebLinks$: (caseKey: Number) => Observable<any> = jest.fn().mockReturnValue(new Observable());
    getCaseSupportUri$: (caseKey: Number) => Observable<any> = jest.fn();
    getScreenControl$: (caseKey: Number, programId: string) => Observable<any> = jest.fn();
    getCaseViewData$: () => Observable<CaseViewViewData> = jest.fn();
    getCaseRenewalsData$: (caseKey: Number, screenCriteriaKey: Number) => Observable<any> = jest.fn();
    getStandingInstructions$ = jest.fn();
    getImportanceLevelAndEventNoteTypes$ = jest.fn();
    resetChanges$ = new BehaviorSubject(false);
    hasPendingChanges$ = new BehaviorSubject(false);
    updateCaseDetails$ = jest.fn();
    errorDetails$ = new Subject<Array<ValidationError>>();
    getCaseChecklistTypes$ = jest.fn();
    getCaseChecklistData$ = jest.fn();
    getCaseChecklistDataHybrid$ = jest.fn();
    eventDate = jest.fn();
    getChecklistDocuments$ = jest.fn();
    getCaseId$: (caseRef: string) => Promise<any> = jest.fn();
}