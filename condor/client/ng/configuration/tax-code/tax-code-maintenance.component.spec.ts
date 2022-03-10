import { FormControl, NgForm, Validators } from '@angular/forms';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { TaxCodeMock } from 'mocks/tax-code.mock';
import { TaxCodeMaintenanceComponent } from './tax-code-maintenance.component';

describe('TaxCodeMaintenanceComponent', () => {
    let component: TaxCodeMaintenanceComponent;
    const notificationService = new NotificationServiceMock();
    const ipxNotificationService = new IpxNotificationServiceMock();
    const service = new TaxCodeMock();
    beforeEach(() => {
        component = new TaxCodeMaintenanceComponent(service as any, notificationService as any,
            ipxNotificationService as any);
        component.ngForm = new NgForm(null, null);
        component.ngForm.form.addControl('description', new FormControl(null, Validators.required));
    });
    it('should initialize TaxCodeMaintenanceComponent', () => {
        expect(component).toBeTruthy();
    });
    it('should call save method', () => {
        component.ngForm.form.controls.description.setValue('123');
        component.save();
        expect(service.saveTaxCode).toHaveBeenCalled();
    });
    it('should call validate method', () => {
        expect(component.validate()).toEqual(false);
    });
    it('should call onClose method', () => {
        spyOn(component.searchRecord, 'emit');
        component.searchRecord.emit(1);
        component.onClose();
        expect(component.searchRecord.emit).toHaveBeenCalledWith(1);
        component.ngForm.form.controls.description.setValue('123');
        component.ngForm.form.controls.description.markAsTouched();
        component.ngForm.form.controls.description.markAsDirty();
        component.onClose();
        expect(component.modalRef).toBeTruthy();
        expect(ipxNotificationService.openDiscardModal).toHaveBeenCalled();
    });
});