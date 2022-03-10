
import { FormControl, NgForm, Validators } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { of, Subject } from 'rxjs';
import { BulkUpdateServiceMock } from '../bulk-update.service.mock';
import { StatusUpdateConfirmationComponent } from './status-update-confirmation.component';

describe('BulkUpdateConfirmationComponent', () => {
    let component: StatusUpdateConfirmationComponent;
    const bsModalRefMock = new BsModalRefMock();
    const bulkUpdateService = new BulkUpdateServiceMock();
    const changeDetectorRef = new ChangeDetectorRefMock();
    beforeEach(() => {
        component = new StatusUpdateConfirmationComponent(bsModalRefMock as any, bulkUpdateService as any, changeDetectorRef as any);
        component.ngForm = new NgForm(null, null);
        component.ngForm.form.addControl('statusConfirmation', new FormControl(null, Validators.required));
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate close', () => {
        component.onClose = new Subject();
        component.close();
        expect(bsModalRefMock.hide).toHaveBeenCalled();
    });

    it('validate submit with invalid data', () => {
        component.onClose = new Subject();
        component.confirmationPassword = '';
        const result = component.submit();
        expect(result).toBeFalsy();
    });

    it('validate submit with invalid data', () => {
        component.onClose = new Subject();
        component.confirmationPassword = 'abc';
        bulkUpdateService.checkStatusPassword = jest.fn().mockReturnValue(of(false));
        component.ngForm.controls.statusConfirmation.setErrors = jest.fn();
        component.submit();
        expect(bulkUpdateService.checkStatusPassword).toHaveBeenCalledWith(component.confirmationPassword);
        expect(component.ngForm.controls.statusConfirmation.setErrors).toHaveBeenCalled();
    });

    it('validate submit with valid data', () => {
        component.onClose = new Subject();
        component.confirmationPassword = 'abc';
        bulkUpdateService.checkStatusPassword = jest.fn().mockReturnValue(of(true));
        const result = component.submit();
        expect(bulkUpdateService.checkStatusPassword).toHaveBeenCalledWith(component.confirmationPassword);
        expect(bsModalRefMock.hide).toHaveBeenCalled();
    });
});