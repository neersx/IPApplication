import { FormControl, NgForm, Validators } from '@angular/forms';
import { BsModalRefMock } from 'mocks';
import { ForwardReminderModalComponent } from './forward-reminder-modal.component';

describe('ForwardReminderModalComponent', () => {
    let component: ForwardReminderModalComponent;
    let modalRef: BsModalRefMock;
    beforeEach(() => {
        modalRef = new BsModalRefMock();
        component = new ForwardReminderModalComponent(modalRef as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('verify save method', () => {
        component.save();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify onClose method', () => {
        component.onClose();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify isValid method with valid name', () => {
        component.form = new NgForm(null, null);
        component.form.form.addControl('names', new FormControl(null, Validators.required));
        component.form.controls.names.setValue([{ key: '123', value: 'Test name' }]);
        component.names = [{ key: '123', value: 'Test name' }];
        const result = component.isValid();
        expect(result).toBeTruthy();
    });

    it('verify isValid method with invalid name', () => {
        component.form = new NgForm(null, null);
        component.form.form.addControl('names', new FormControl(null, Validators.required));
        const result = component.isValid();
        expect(result).toBeFalsy();
    });
});