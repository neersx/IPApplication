import { FormControl, NgForm, Validators } from '@angular/forms';
import { BsModalRefMock } from 'mocks';
import { SendEmailModalComponent } from './send-email-modal.component';

describe('SendEmailModalComponent', () => {
    let component: SendEmailModalComponent;
    let modalRef: BsModalRefMock;
    beforeEach(() => {
        modalRef = new BsModalRefMock();
        component = new SendEmailModalComponent(modalRef as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('verify onClose method', () => {
        component.onClose();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify isValid method with valid name', () => {
        component.form = new NgForm(null, null);
        component.form.form.addControl('names', new FormControl(null, Validators.required));
        component.form.controls.names.setValue([{ key: '123', value: 'Test name', displayEmail: 'test1@email.com' }]);
        component.names = [{ key: '123', value: 'Test name', displayEmail: 'test123@email.com' }];
        component.namesWithEmail = [{ key: '123', value: 'Test name', displayEmail: 'test123@email.com' }];
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