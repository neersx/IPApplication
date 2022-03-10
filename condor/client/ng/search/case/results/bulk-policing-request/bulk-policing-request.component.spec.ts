
import { NgForm } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { Subject } from 'rxjs';
import { BulkUpdateReasonData } from 'search/case/bulk-update/bulk-update.data';
import { BulkPolicingRequestComponent } from './bulk-policing-request.component';
import { BulkPolicingServiceMock } from './bulk-policing-service.mock';

describe('BulkPolicingRequestComponent', () => {
    let component: BulkPolicingRequestComponent;
    const bsModalRefMock = new BsModalRefMock();
    const bulkPolicingService = new BulkPolicingServiceMock();
    const changeDetectorRef = new ChangeDetectorRefMock();
    beforeEach(() => {
        component = new BulkPolicingRequestComponent(bsModalRefMock as any, bulkPolicingService as any, changeDetectorRef as any);
        component.reasonData = new BulkUpdateReasonData();
        component.ngForm = new NgForm(null, null);

    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();

        bulkPolicingService.getBulkPolicingViewData().subscribe(() => {
            expect(component.textTypes).toEqual(2);
            expect(component.allowRichText).toEqual(false);
        });
    });

    it('validate reasonChange with blank reason data and valid reason text', () => {
        component.reasonData.textType = undefined;
        component.reasonData.notes = 'reason notes';
        component.reasonChange();
        expect(component.reasonData.notes).toEqual('');
    });

    it('validate close', () => {
        component.onClose = new Subject();
        component.close();
        expect(bsModalRefMock.hide).toHaveBeenCalled();
    });

    it('validate submit with invalid data', () => {
        component.onClose = new Subject();
        component.reasonData = { notes: 'test notes', textType: undefined };
        component.submit();
        expect(component.reasonData.notes).toEqual('');
    });

    it('validate submit with valid data', () => {
        component.onClose = new Subject();
        component.caseAction = { key: 1, code: 'AS'};
        component.reasonData = { notes: 'test notes', textType: 'AB' };
        component.submit();
        expect(bulkPolicingService.sendBulkPolicingRequest).toHaveBeenCalled();
        bulkPolicingService.getBulkPolicingViewData(component.selectedCases, component.caseAction.code, component.reasonData).subscribe(() => {
            expect(bsModalRefMock.hide).toHaveBeenCalled();
        });
    });
});