import { DateServiceMock } from 'ajs-upgraded-providers/mocks/date-service.mock';
import { BsModalRefMock, DateHelperMock } from 'mocks';
import { Observable } from 'rxjs';
import { FinaliseAdHocDateComponent } from './finalise-adhoc-date.component';

describe('FinaliseAdHocDateComponent', () => {
    let component: FinaliseAdHocDateComponent;
    const modalRef = new BsModalRefMock();
    const dateService = new DateServiceMock();
    const dateHelper = new DateHelperMock();
    const adHocDateService = {
        finalise: jest.fn().mockReturnValue(new Observable()),
        bulkFinalise: jest.fn().mockReturnValue(new Observable())
    };
    beforeEach(() => {
        component = new FinaliseAdHocDateComponent(modalRef as any, dateService as any, adHocDateService as any, dateHelper as any);
    });
    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('should call ngOnInit', () => {
        component.finaliseData = { adHocDateFor: null, reference: null, message: null, dueDate: null, resolveReasons: 'Reason', alertId: 10, isBulkUpdate: false, selectedTaskPlannerRowKeys: null, searchRequestParams: null };
        component.ngOnInit();
        expect(component.dateFormat).toEqual('DD-MMM-YYYY');
        expect(component.form.valid).toEqual(true);
        expect(component.finaliseData.resolveReasons).toEqual('Reason');
    });

    it('should call disableFinalise', () => {
        component.finaliseData = { adHocDateFor: null, reference: null, message: null, dueDate: null, resolveReasons: 'Reason', alertId: 10, isBulkUpdate: false, selectedTaskPlannerRowKeys: null, searchRequestParams: null };
        component.ngOnInit();
        const result = component.disableFinalise();
        expect(result).toEqual(false);
    });

    it('should OnClose', () => {
        component.onClose();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('should finalise', () => {
        component.finaliseData = { adHocDateFor: null, reference: null, message: null, dueDate: null, resolveReasons: null, alertId: 10, isBulkUpdate: false, selectedTaskPlannerRowKeys: null, searchRequestParams: null };
        component.ngOnInit();
        component.form.controls.reason.setValue('2');
        component.finalise();
        expect(component.saveAdhocDetails.alertId).toEqual(10);
        expect(adHocDateService.finalise).toHaveBeenCalled();
    });

    it('should bulkfinalise', () => {
        component.finaliseData = { adHocDateFor: null, reference: null, message: null, dueDate: null, resolveReasons: null, alertId: null, isBulkUpdate: true, selectedTaskPlannerRowKeys: ['10', '11'], searchRequestParams: null };
        component.ngOnInit();
        component.form.controls.reason.setValue('2');
        component.finalise();
        expect(component.bulkAdhocDetails.selectedTaskPlannerRowKeys).toEqual(['10', '11']);
        expect(adHocDateService.bulkFinalise).toHaveBeenCalled();
    });
});