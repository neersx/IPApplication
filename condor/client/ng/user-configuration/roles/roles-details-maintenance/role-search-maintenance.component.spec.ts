import { FormControl, NgForm, Validators } from '@angular/forms';
import { IpxNotificationServiceMock, NotificationServiceMock, RoleSearchMock } from 'mocks';
import { RoleSearchState } from '../role-search.service';
import { RoleSearchMaintenanceComponent } from './role-search-maintenance.component';

describe('RoleSearchMaintenanceComponent', () => {
    let component: RoleSearchMaintenanceComponent;
    const service = new RoleSearchMock();
    const notificationService = new NotificationServiceMock();
    const ipxNotificationService = new IpxNotificationServiceMock();
    beforeEach(() => {
        component = new RoleSearchMaintenanceComponent(service as any, notificationService as any,
            ipxNotificationService as any);
        component.dataItem = { description: 'dis', isExternal: true };
        component.ngForm = new NgForm(null, null);
        component.ngForm.form.addControl('description', new FormControl(null, Validators.required));
    });
    it('should initialize RoleSearchMaintenanceComponent', () => {
        expect(component).toBeTruthy();
    });
    it('should call ngOnInit method', () => {
        component.ngOnInit();
        expect(component.formData.isExternal).toEqual(false);
        component.states = RoleSearchState.DuplicateRole;
        component.ngOnInit();
        expect(component.formData.description).toEqual('dis');
        expect(component.formData.isExternal).toEqual(true);
    });
    it('should call save method', () => {
        component.ngForm.form.controls.description.setValue('123');
        component.save();
        expect(service.saveRole).toHaveBeenCalled();
    });
    it('should call title method', () => {
        component.states = RoleSearchState.DuplicateRole;
        const result = component.title();
        expect(result).toEqual('roleDetails.duplicateRole');
        component.states = RoleSearchState.Adding;
        const result1 = component.title();
        expect(result1).toEqual('roleDetails.addrole');
        component.states = RoleSearchState.Updating;
        const result2 = component.title();
        expect(result2).toEqual('roleDetails.editRol');
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