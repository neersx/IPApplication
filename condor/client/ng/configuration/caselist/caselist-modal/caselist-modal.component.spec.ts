import { FormControl, FormGroup, Validators } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { Observable } from 'rxjs';
import { CaseListPicklistComponent } from 'shared/component/typeahead/ipx-picklist/ipx-picklist-modal-maintenance/case-list-picklist/case-list-picklist.component';
import { CaselistModalComponent } from './caselist-modal.component';

describe('CaselistModalComponent', () => {
    let component: CaselistModalComponent;
    let translateServiceMock: TranslateServiceMock;
    let modalRef: BsModalRefMock;
    const cdrMock = new ChangeDetectorRefMock();
    const picklistMaintenanceServiceMock = {
        modalStates$: {
            getValue: () => {
                return {
                    canAdd: true,
                    canSave: false
                };
            }
        },
        addOrUpdate$: jest.fn().mockReturnValue(new Observable()),
        maintenanceMetaData$: {
            getValue: jest.fn()
        },
        discard$: jest.fn().mockReturnValue(new Observable())
    };

    beforeEach(() => {
        translateServiceMock = new TranslateServiceMock();
        modalRef = new BsModalRefMock();
        component = new CaselistModalComponent(modalRef as any, translateServiceMock as any);
        component.caseListComponent = new CaseListPicklistComponent(
            picklistMaintenanceServiceMock as any,
            {} as any,
            cdrMock as any,
            {} as any,
            {} as any
        );

    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();
        expect(component.modalTitle).toEqual('picklist.caselist.addTitle');
    });

    it('validate canSave', () => {
        const result = component.canSave();
        expect(result).toBeFalsy();
    });

    it('validate close with form dirty', () => {
        component.caseListComponent.form = new FormGroup({
            value: new FormControl(null, [Validators.required, Validators.required])
        });
        component.caseListComponent.form.controls.value.setValue('test 1');
        component.caseListComponent.form.markAsDirty();
        component.close();
        expect(picklistMaintenanceServiceMock.discard$).toHaveBeenCalled();
    });

    it('validate close with form pristine', () => {
        component.caseListComponent.form = new FormGroup({
            value: new FormControl(null, [Validators.required, Validators.required])
        });
        component.close();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('validate save', () => {
        component.save();
        expect(picklistMaintenanceServiceMock.addOrUpdate$).toHaveBeenCalled();
    });

});
