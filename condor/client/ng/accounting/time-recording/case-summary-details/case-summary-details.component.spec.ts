import { ChangeDetectorRefMock } from 'mocks';
import { of, Subscription } from 'rxjs';
import { debounceTime } from 'rxjs/operators';
import { TimeRecordingService } from '../time-recording-service';
import { CaseSummaryDetailsComponent } from './case-summary-details.component';
import { CaseSummaryServiceMock } from './case-summary-service.mock';
import { CaseSummaryService } from './case-summary.service';

describe('CaseSummaryDetailsComponent', () => {
    let component: CaseSummaryDetailsComponent;
    let caseSummaryService: CaseSummaryServiceMock;
    let timeRecordingService: TimeRecordingService;
    let cdRef: any;

    beforeEach(() => {
        caseSummaryService = new CaseSummaryServiceMock();
        timeRecordingService = new TimeRecordingService(null, null);
        cdRef = new ChangeDetectorRefMock();
        component = new CaseSummaryDetailsComponent(caseSummaryService as any, timeRecordingService, cdRef);
    });

    describe('loading the data', () => {
        beforeEach(() => {
            caseSummaryService.getCaseSummary = jest.fn().mockReturnValue(of({ caseKey: '555', caseReference: 'abc-XYZ'}));
            component.ngAfterViewInit();
        });
        it('calls the service to retrieve case summary details', done => {
            timeRecordingService.rowSelected.next(1234);
            timeRecordingService.rowSelected.pipe(debounceTime(300)).subscribe(() => {
                expect(caseSummaryService.getCaseSummary).toHaveBeenCalledWith(1234);
                expect(cdRef.markForCheck).toHaveBeenCalled();
                expect(component.caseSummary).toEqual(expect.objectContaining({ caseKey: '555', caseReference: 'abc-XYZ' }));
                expect(component.instructorNameType).toBe('');
                done();
            });
        });
        it('does not call the service when case is cleared', done => {
            timeRecordingService.rowSelected.next(null);
            timeRecordingService.rowSelected.pipe(debounceTime(300)).subscribe(() => {
                expect(caseSummaryService.getCaseSummary).not.toHaveBeenCalled();
                expect(cdRef.markForCheck).toHaveBeenCalled();
                expect(component.caseSummary).toBeNull();
                expect(component.instructorNameType).toBe('');
                done();
            });
        });
        it('sets instructor name type to empty string where not available', done => {
            caseSummaryService.getCaseSummary = jest.fn().mockReturnValue(of({ caseKey: '1234', caseReference: 'abc-XYZ', instructor: {nameKey: 5968, type: 'X-Client'} }));
            component.ngAfterViewInit();
            timeRecordingService.rowSelected.next(1234);
            timeRecordingService.rowSelected.pipe(debounceTime(300)).subscribe(() => {
                expect(caseSummaryService.getCaseSummary).toHaveBeenCalledWith(1234);
                expect(cdRef.markForCheck).toHaveBeenCalled();
                expect(component.caseSummary).toEqual(expect.objectContaining({ caseKey: '1234', caseReference: 'abc-XYZ' }));
                expect(component.instructorNameType).toEqual('X-Client');
                done();
            });
        });
    });
    it('unsubscribes on destroy', () => {
        const unsubscribe = jest.fn();
        component.subscription = new Subscription(unsubscribe);
        component.ngOnDestroy();
        expect(unsubscribe).toHaveBeenCalled();
    });
});
