import { FormBuilder } from '@angular/forms';
import { CaseValidCombinationServiceMock, ChangeDetectorRefMock } from 'mocks';
import { HeaderEntityType } from '../billing-maintenance/case-debtor.model';
import { BillingStepsPersistanceService } from '../billing-steps-persistance.service';
import { BillingServiceMock, ItemDateValidatorMock } from '../billing.mocks';
import { BillingHeaderComponent } from './billing-header.component';

describe('BillingHeaderComponent', () => {
    let component: BillingHeaderComponent;
    let cdr: ChangeDetectorRefMock;
    let service: BillingServiceMock;
    let itemDateValidator: ItemDateValidatorMock;
    let fb: FormBuilder;
    let cvs: CaseValidCombinationServiceMock;
    let stepService: BillingStepsPersistanceService;

    beforeEach(() => {
        service = new BillingServiceMock();
        cdr = new ChangeDetectorRefMock();
        itemDateValidator = new ItemDateValidatorMock();
        fb = new FormBuilder();
        cvs = new CaseValidCombinationServiceMock();
        stepService = new BillingStepsPersistanceService();
        component = new BillingHeaderComponent(service as any, fb as any, cdr as any, itemDateValidator as any, stepService as any, cvs as any);

        component.formGroup = {
            controls: {
                currentAction: { value: { key: 23, code: 'AS' } },
                useRenewalDebtor: { value: false },
                entity: { setValue: jest.fn() }
            }
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('initialize component', () => {
        it('should set header values', (done) => {
            jest.spyOn(component, 'createFormGroup');
            component.ngOnInit();
            service.openItemData$.subscribe((data) => {
                expect(component.openItemData).toBe(data);
                expect(component.createFormGroup).toHaveBeenCalled();
                expect(component.defaultLanguage).toBe('English');
                done();
            });
            service.currentLanguage$.subscribe((data) => {
                expect(component.defaultLanguageId).toBe(data.id);
                expect(component.defaultLanguage).toBe(data.description);
                done();
            });
            service.currentAction$.subscribe((data) => {
                expect(component.formDataForVC).toBe(data);
                expect(cvs.initFormData).toBeCalled();
                done();
            });

            service.revertChanges$.subscribe((data) => {
                expect(component.formGroup).not.toBe(null);
                expect(data.entity).toBe(HeaderEntityType.ActionPicklist);
                done();
            });
        });
    });

    it('should change action value', (done) => {
        jest.spyOn(component, 'initializeStepData');
        component.ngAfterViewInit();
        service.openItemData$.subscribe((data) => {
            expect(component.formGroup.controls.entity.setValue).toHaveBeenCalledWith(data.ItemEntityId);
            expect(component.initializeStepData).toHaveBeenCalled();
            done();
        });
    });

    it('should call on action change', () => {
        const action = { key: 23, code: 'AS' };
        component.oldNewAction = {
            entity: HeaderEntityType.ActionPicklist,
            oldValue: { key: 223, code: 'RS' },
            value: action
        };
        jest.spyOn(component, 'setOldNewAction');
        component.onActionChange(action);
        expect(component.setOldNewAction).toHaveBeenCalled();
        expect(component.formGroup.controls.currentAction.value).toEqual(action);
    });

    it('should call on renewal flag change', () => {
        component.oldNewRenewalCheck = {
            entity: HeaderEntityType.RenewalCheckBox,
            oldValue: false,
            value: true
        };
        jest.spyOn(component, 'setOldNewRenewalCheck');
        component.onRenewalDebtorChange(true);
        expect(component.setOldNewRenewalCheck).toHaveBeenCalled();
        expect(component.formGroup.controls.useRenewalDebtor.value).toBeFalsy();
    });
});