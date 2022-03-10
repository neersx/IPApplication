import { fakeAsync, tick } from '@angular/core/testing';
import { TimeRecordingServiceMock } from 'accounting/time-recording/time-recording.mock';
import { BehaviorSubjectMock, ChangeDetectorRefMock } from 'mocks';
import { of, Subscription } from 'rxjs';
import { debounceTime } from 'rxjs/operators';
import { CaseSummaryService } from '../../time-recording/case-summary-details/case-summary.service';
import { TimeRecordingService } from '../../time-recording/time-recording-service';
import { AccountingService } from '../accounting.service';
import { CaseFinancialComponent } from './case-financial.component';

describe('CaseFinancialComponent', () => {
    let c: CaseFinancialComponent;
    let caseSummaryService: CaseSummaryService;
    let accountingService: AccountingService;
    let timeRecordingService: any;
    let cdRef: any;

    beforeEach(() => {
        caseSummaryService = new CaseSummaryService(null);
        accountingService = new AccountingService(null);
        timeRecordingService = new TimeRecordingService();
        cdRef = new ChangeDetectorRefMock();
        c = new CaseFinancialComponent(caseSummaryService, timeRecordingService, accountingService, cdRef);
    });

    describe('loading the data', () => {
        beforeEach(() => {
            caseSummaryService.getCaseFinancials = jest.fn().mockReturnValue(of({ id: 1234, wip: 1 }));
            accountingService.getCurrencyCode = jest.fn();
            accountingService.getViewWipPermission = jest.fn().mockReturnValue(true);
            c.ngOnInit();
            expect(accountingService.getCurrencyCode).toHaveBeenCalled();
            expect(accountingService.getViewWipPermission).toHaveBeenCalled();
        });
        it('calls does not call service when case is cleared', fakeAsync(() => {
            timeRecordingService.rowSelected.next(null);
            tick(300);
            expect(caseSummaryService.getCaseFinancials).not.toHaveBeenCalled();
            expect(cdRef.detectChanges).toHaveBeenCalled();
            expect(c.caseFinancials).toBeUndefined();
            expect(c.canViewWip).toBeTruthy();
        }));
        it('calls the service to retrieve case financial data', fakeAsync(() => {
            timeRecordingService.rowSelected.next(1234);
            tick(300);
            expect(caseSummaryService.getCaseFinancials).toHaveBeenCalledWith(1234);
            expect(cdRef.detectChanges).toHaveBeenCalled();
            expect(c.caseFinancials).toEqual({ id: 1234, wip: 1 });
            expect(c.canViewWip).toBeTruthy();
            expect(c.hasWipBalance).toBeTruthy();
        }));
    });
    it('unsubscribes on destroy', () => {
        const unsubscribe = jest.fn();
        c.subscription = new Subscription(unsubscribe);
        c.ngOnDestroy();
        expect(unsubscribe).toHaveBeenCalled();
    });
});
