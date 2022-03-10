import { BsModalRef } from 'ngx-bootstrap/modal';
import { Period } from '../time-recording-model';
import { ChangeEntryDateComponent } from './change-entry-date.component';

describe('Change Entry Date Component', () => {

    let c: ChangeEntryDateComponent;
    let modalRef: BsModalRef;

    beforeEach(() => {
        modalRef = new BsModalRef();
        modalRef.hide = jest.fn();
        c = new ChangeEntryDateComponent(modalRef);
    });

    describe('date validations', () => {
        it('returns true if dates are equivalent', () => {
            c.initialDate = new Date();
            c.newDate = new Date();
            const result = c.sameDates();
            expect(result).toBeTruthy();
        });
        it('returns false if dates are different', () => {
            c.initialDate = new Date(2000, 1, 1);
            c.newDate = new Date(2000, 1, 2);
            const result = c.sameDates();
            expect(result).toBeFalsy();
        });
        it('returns false if months are different', () => {
            c.initialDate = new Date(2000, 1, 1);
            c.newDate = new Date(2000, 2, 1);
            const result = c.sameDates();
            expect(result).toBeFalsy();
        });
        it('returns false if years are different', () => {
            c.initialDate = new Date(2000, 1, 1);
            c.newDate = new Date(1999, 1, 1);
            const result = c.sameDates();
            expect(result).toBeFalsy();
        });
        it('sets error if the date belongs to open period, if posted entry date is being changed', () => {
            c.item = { entryNo: 10, isPosted: true };

            const openPeriods = new Array<Period>();
            openPeriods.push(new Period({ startDate: new Date(2000, 10, 10), endDate: new Date(2001, 10, 10) }));
            openPeriods.push(new Period({ startDate: new Date(2011, 10, 10), endDate: new Date(2012, 10, 10) }));
            const form = { controls: { newEntryDate: { setErrors: jest.fn() } } };

            const result = c.isValidDate(new Date(2010, 10, 10), openPeriods, form as any);
            expect(result).toBeFalsy();
            expect(form.controls.newEntryDate.setErrors).toHaveBeenCalledWith({ 'timeRecording.selectOpenPeriod': true });
        });

        it('does not set error if the date belongs to open period, if posted entry date is being changed', () => {
            c.item = { entryNo: 10, isPosted: true };

            const openPeriods = new Array<Period>();
            openPeriods.push(new Period({ startDate: new Date(2000, 10, 10), endDate: new Date(2001, 10, 10) }));
            openPeriods.push(new Period({ startDate: new Date(2011, 10, 10), endDate: new Date(2012, 10, 10) }));
            const form = { controls: { newEntryDate: { setErrors: jest.fn() } } };

            const result = c.isValidDate(new Date(2011, 11, 11), openPeriods, form as any);
            expect(result).toBeTruthy();
            expect(form.controls.newEntryDate.setErrors).not.toHaveBeenCalled();
        });
    });

    describe('Clicking OK', () => {
        it('emits event and closes the modal', () => {
            c.ok();
            expect(modalRef.hide).toHaveBeenCalled();
        });
    });

    describe('Clicking Cancel', () => {
        it('closes the modal', () => {
            c.close();
            expect(modalRef.hide).toHaveBeenCalled();
        });
    });
});