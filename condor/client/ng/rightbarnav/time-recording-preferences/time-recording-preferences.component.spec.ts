
import { fakeAsync, tick } from '@angular/core/testing';
import { AbstractControl, FormControl, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { TimeRecordingPreferencesComponent } from './time-recording-preferences.component';
import { TimeRecordingPreferenceService } from './time-recording-preferences.service';

describe('TimeRecordingPreferencesComponent', () => {
    let c: TimeRecordingPreferencesComponent;
    let changeDetectorRefMock: ChangeDetectorRefMock;
    let preferences: TimeRecordingPreferenceService;
    let notifications: NotificationServiceMock;
    let ipxNotifications: any;
    let ipxDestroy: any;

    beforeEach(() => {
        changeDetectorRefMock = new ChangeDetectorRefMock();
        preferences = new TimeRecordingPreferenceService(null);
        notifications = new NotificationServiceMock();
        ipxNotifications = new IpxNotificationServiceMock();
        ipxDestroy = of();
        c = new TimeRecordingPreferencesComponent(changeDetectorRefMock as any, preferences, notifications as any, ipxNotifications, ipxDestroy);
        c.viewData = { onSuccess: jest.fn() };
    });

    it('should call loadPreferences on init', () => {
        const loadPrefSpy = preferences.loadPreferences = jest.fn().mockReturnValue(of(null));
        c.ngOnInit();
        expect(loadPrefSpy).toHaveBeenCalled();
    });

    it('should set the loader flag to false', () => {
        preferences.loadPreferences = jest.fn().mockReturnValue(of([1, 2]));
        c.isLoading = true;
        preferences.loadPreferences().subscribe((res: any) => {
            expect(c.isLoading).toBe(false);
        });
    });

    it('should call savePreferences on apply', (done) => {
        c.settings = ['anything'];
        const savePrefSpy = preferences.savePreferences = jest.fn().mockReturnValue(of([{isDefault: true}, {isDefault: false}]));
        c.apply(null);
        preferences.savePreferences(c.settings).subscribe(() => {
            expect(notifications.info).toHaveBeenCalled();
            expect(c.hasUserPreferences).toBeTruthy();
            done();
        });
        expect(savePrefSpy).toHaveBeenCalledWith(c.settings);
    });

    it('should reset the form', () => {
        const form = new NgForm(null, null);
        c.reset(form);
        expect(form.form.pristine).toBeTruthy();
    });

    it ('should reset preferences to default settings', fakeAsync(() => {
        const settingsData = [{ id: 101, booleanValue: false, isDefault: true }, { id: 102, booleanValue: true, isDefault: false }, { id: 103, integerValue: 5, isDefault: true, dataType: 'I' }, { id: 104, integerValue: 12, isDefault: false, dataType: 'I' }];
        const form = new NgForm(null, null);
        form.form.addControl('userPreference_101', new FormControl(true));
        form.form.addControl('userPreference_102', new FormControl(false));
        form.form.addControl('userPreference_103', new FormControl(8));
        form.form.addControl('userPreference_104', new FormControl(7));
        c.settings = ['anything'];
        ipxNotifications.modalRef.content.confirmed$ = of(true).pipe(delay(100));
        const resetSpy = preferences.resetPreferences = jest.fn().mockReturnValue(of(settingsData));
        c.resetToDefault(form);
        expect(ipxNotifications.openConfirmationModal).toHaveBeenCalled();
        expect(ipxNotifications.openConfirmationModal.mock.calls[0][0]).toBe('userPreferences.resetToDefault.confirmation.title');
        expect(ipxNotifications.openConfirmationModal.mock.calls[0][1]).toBe('userPreferences.resetToDefault.confirmation.message');
        expect(ipxNotifications.openConfirmationModal.mock.calls[0][2]).toBe('userPreferences.resetToDefault.confirmation.confirm');
        tick(100);
        expect(notifications.info).toHaveBeenCalled();
        expect(c.hasUserPreferences).toBeTruthy();
        expect(resetSpy).toHaveBeenCalled();
        expect(c.settings).toEqual(expect.objectContaining(settingsData));
    }));

    it('should set the default boolean values on preview', fakeAsync(() => {
        const form = new NgForm(null, null);
        form.form.addControl('userPreference_101', new FormControl(null));
        form.form.addControl('userPreference_102', new FormControl(null));
        form.form.addControl('userPreference_103', new FormControl(null));
        form.form.addControl('userPreference_104', new FormControl(null));
        c.settings = [{ id: 101, defaultBooleanValue: true, booleanValue: false, dataType: 'B' }, { id: 102, defaultBooleanValue: false, booleanValue: true, dataType: 'B' }, { id: 103, integerValue: 5, defaultIntegerValue: 10, isDefault: true, dataType: 'I' }, { id: 104, integerValue: 12, defaultIntegerValue: 15, isDefault: false, dataType: 'I' }];
        ipxNotifications.modalRef.content.confirmed$ = of(true).pipe(delay(100));
        c.previewDefault(form);
        tick(100);
        expect(form.form.get('userPreference_101').value).toBe(true);
        expect(form.form.get('userPreference_102').value).toBe(false);
        expect(form.form.get('userPreference_103').value).toBe(10);
        expect(form.form.get('userPreference_104').value).toBe(15);
    }));

    describe('validateNumber', () => {
        beforeEach(() => {
            const form = new NgForm(null, null);
            form.form.addControl('userPreference_101', new FormControl(null));
            c.f = form;
        });
        it('checks for non-negative whole integer', () => {
            c.validateNumber(-1, '102');
            expect(c.hasErrors).toBeFalsy();
            c.validateNumber(10.1, '101');
            expect(c.hasErrors).toBeTruthy();
            c.validateNumber(10, '101');
            expect(c.hasErrors).toBeFalsy();
            c.validateNumber(-1, '101');
            expect(c.hasErrors).toBeTruthy();
            c.validateNumber(0, '101');
            expect(c.hasErrors).toBeFalsy();
        });
        it('checks for max value', () => {
            c.validateNumber(49, '101', 50);
            expect(c.hasErrors).toBeFalsy();
            c.validateNumber(51, '101', 50);
            expect(c.hasErrors).toBeTruthy();
            c.validateNumber(50, '101', 50);
            expect(c.hasErrors).toBeFalsy();
        });
    });

});
