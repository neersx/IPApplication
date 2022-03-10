import { FormControl, NgForm, Validators } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { DeferReminderToDateModalComponent } from './defer-reminder-to-date-modal.component';

describe('DeferReminderToDateModalComponent', () => {
    let component: DeferReminderToDateModalComponent;
    let modalRef: BsModalRefMock;
    let cdRef: ChangeDetectorRefMock;
    beforeEach(() => {
        modalRef = new BsModalRefMock();
        cdRef = new ChangeDetectorRefMock();
        component = new DeferReminderToDateModalComponent(modalRef as any, cdRef as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('verify deferReminder method', () => {
        component.deferReminder();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify onClose method', () => {
        component.onClose();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify isValid method with valid date', () => {
        component.form = new NgForm(null, null);
        component.form.form.addControl('enteredDate', new FormControl(null, Validators.required));
        component.form.controls.enteredDate.setValue(new Date());
        component.enteredDate = new Date();
        const result = component.isValid();
        expect(result).toBeTruthy();
    });

    it('verify isValid method with invalid date', () => {
        component.form = new NgForm(null, null);
        component.form.form.addControl('enteredDate', new FormControl(null, Validators.required));
        component.enteredDate = null;
        const result = component.isValid();
        expect(result).toBeFalsy();
    });
});