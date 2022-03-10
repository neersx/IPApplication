import { async } from '@angular/core/testing';
import { FormControl, NgForm, Validators } from '@angular/forms';
import { ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { RecordalStepElementControlsComponent } from './recordal-step-elements-controls.component';

describe('Recordal Step Element Controls Component', () => {
    let c: RecordalStepElementControlsComponent;
    const cdr = new ChangeDetectorRefMock();
    const translateService = new TranslateServiceMock();
    const affectedCasesService = {
        getStepElementRowFormData: jest.fn().mockReturnValue({ stepId: 1, rowId: 2, form: NgForm, formData: {} }),
        clearStepElementRowFormData: jest.fn(), setStepElementRowFormData: jest.fn(), getCurrentAddressForName: jest.fn(), getRecordalStepElements: jest.fn().mockReturnValue(of([{ elementId: 1, id: 1 }]))
    };
    const knownNameTypes = { Owner: 'o' };
    beforeEach(() => {
        c = new RecordalStepElementControlsComponent(affectedCasesService as any, cdr as any, knownNameTypes as any, translateService as any);
        c.dataItem = { nameType: 'search', id: 1, typeText: 'CURRENT' };
        c.form = new NgForm(null, null);
        c.form.form.addControl('rootFolder', new FormControl(null, Validators.required));
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('should call Oninit', async(() => {
        c.ngOnInit();
        expect(affectedCasesService.getStepElementRowFormData).toHaveBeenCalled();
        expect(c.namePickListExternalScope.filterNameType).toEqual('search');
        expect(c.namePickListExternalScope.isFilterByNameType).toEqual(true);
        expect(c.ownerPickListExternalScope.filterNameType).toEqual('o');
        expect(c.ownerPickListExternalScope.nameTypeDescription).toEqual('picklist.owner');
    }));

    it('should call revert', async(() => {
        c.isRevertDisabled = false;
        c.revert({}, 1);
        expect(affectedCasesService.clearStepElementRowFormData).toHaveBeenCalled();
        expect(affectedCasesService.getRecordalStepElements).toHaveBeenCalled();
        affectedCasesService.getRecordalStepElements().subscribe((response: any) => {
            expect(response[0].elementId).toEqual(1);
            expect(response[0].id).toEqual(1);
            expect(c.isRevertDisabled).toEqual(true);
        });
    }));

    it('should call disableAddress when isAssignedStep is true ', async(() => {
        c.isAssignedStep = true;
        const result = c.disableAddress();
        expect(result).toEqual(true);
    }));

    it('should call disableAddress when isAssignedStep is false ', async(() => {
        c.isAssignedStep = false;
        c.dataItem.typeText = 'false';
        const result = c.disableAddress();
        expect(result).toEqual(false);
    }));

    it('should call onModelChange when type is do ', async(() => {
        c.onModelChange(null, 1, 'do');
        expect(affectedCasesService.setStepElementRowFormData).toHaveBeenCalled();
        expect(c.isRevertDisabled).toEqual(false);
        expect(affectedCasesService.getCurrentAddressForName).toHaveBeenCalled();
        expect(c.formData.addressPicklist).toEqual({});
    }));

    it('should call onModelChange when type is NAME ', async(() => {
        c.onModelChange(null, 1, 'NAME');
        expect(affectedCasesService.setStepElementRowFormData).toHaveBeenCalled();
        expect(c.isRevertDisabled).toEqual(false);
        expect(affectedCasesService.getCurrentAddressForName).toHaveBeenCalled();
        expect(c.formData.addressPicklist).toEqual(null);
    }));
});