import { FormControl, NgForm, Validators } from '@angular/forms';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { BsModalRefMock } from 'mocks';
import { Observable } from 'rxjs';
import { CreateBillsModalComponent } from './create-bills-modal.component';

describe('CreateBillsModalComponent', () => {
    let component: CreateBillsModalComponent;
    let modalRef: BsModalRefMock;
    let appContextService: AppContextServiceMock;
    const wipOverviewService = { isEntityRestrictedByCurrency: jest.fn().mockReturnValue(new Observable()) };
    beforeEach(() => {
        modalRef = new BsModalRefMock();
        appContextService = new AppContextServiceMock();
        component = new CreateBillsModalComponent(modalRef as any, appContextService as any, wipOverviewService as any, {} as any, {} as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('verify ngOnInit', () => {
        component.entities = [{ entityKey: 1, entityName: 'test 1', isDefault: true }];
        component.selectedItems = [{ rowKey: 1, isNonRenewalWip: false, isUseRenewalDebtor: true }];
        component.ngOnInit();
        expect(component.formData.entityId).toEqual(1);
        expect(component.formData.includeNonRenewal).toBeFalsy();
        expect(component.formData.includeRenewal).toBeTruthy();
        expect(component.formData.useRenewalDebtor).toBeTruthy();
    });

    it('verify onClose method', () => {
        component.onClose();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify proceed method', () => {
        component.proceed();
        expect(wipOverviewService.isEntityRestrictedByCurrency).toHaveBeenCalled();
    });

    it('verify isValid method', () => {
        component.form = new NgForm(null, null);
        component.form.form.addControl('entity', new FormControl(null, Validators.required));
        const result = component.isValid();
        expect(result).toBeFalsy();
    });
});