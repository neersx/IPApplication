import { fakeAsync, tick } from '@angular/core/testing';
import { ChangeDetectorRefMock, NotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { TimeRecordingPermissions, UserIdAndPermissions } from '../time-recording-model';
import { TimeRecordingServiceMock, TimeSettingsServiceMock, UserInfoServiceMock } from '../time-recording.mock';
import { TimeRecordingHeaderComponent } from './time-recording-header.component';

describe('TimeRecordingHeaderComponent', () => {
    let settingsService: any;
    let cdRef: any;
    let notificationService: any;
    let timeService: any;
    let userInfo: any;
    let c: TimeRecordingHeaderComponent;

    beforeEach(() => {
        settingsService = new TimeSettingsServiceMock();
        cdRef = new ChangeDetectorRefMock();
        userInfo = new UserInfoServiceMock();
        notificationService = new NotificationServiceMock();
        timeService = new TimeRecordingServiceMock();

        c = new TimeRecordingHeaderComponent(settingsService, cdRef, userInfo, notificationService, timeService);
        settingsService.displaySecondsOnChange = of('abcd');
        settingsService.canFunctionAsOtherStaff = of(false);
    });

    describe('init and ngAfterViewInit', () => {
        it('init creates selectedName formControl', () => {
            c.ngOnInit();
            expect(c.selectedName).not.toBeNull();
        });

        it('init gets value for displaySecondsChange, and disables access to other staff', fakeAsync(() => {
            c.ngOnInit();
            c.ngAfterViewInit();
            tick(100);
            expect(c.displaySeconds).toBe('abcd');
            expect(c.canFunctionAsOtherStaff).toBeFalsy();
        }));

        describe('checking if user can function as other staff', () => {
            beforeEach(() => {
                settingsService.canFunctionAsOtherStaff = of(true);
            });
            it('initialises the staff picklist to the current staff', fakeAsync(() => {
                userInfo.userDetails$ = of({ staffId: 100 , displayName: 'Humpty', isStaff: true});
                settingsService.canFunctionAsOtherStaff = of(true).pipe(delay(10));
                c.ngOnInit();
                const setNameSpy = jest.spyOn(c.selectedName, 'setValue');

                tick(10);
                expect(c.canFunctionAsOtherStaff).toBe(true);
                expect(cdRef.detectChanges).toHaveBeenCalled();

                expect(setNameSpy).toHaveBeenCalledWith({ key: 100, displayName: 'Humpty' }, { emitEvent: false });
            }));

            it('logged in user display name set in selectedName formControl', () => {
                jest.spyOn(c, 'handleSelectedNameValueChange');
                c.ngOnInit();
                c.initLoggedInUser({ displayName: 'Xyz, Abc' } as any as UserIdAndPermissions);
                expect(c.handleSelectedNameValueChange).toHaveBeenCalled();
            });
            it('sets staff to any default staff overrides if allowed', () => {
                jest.spyOn(c, 'handleSelectedNameValueChange');
                c.ngOnInit();
                c.canFunctionAsOtherStaff = true;
                c.defaultedStaff = {key: -100, displayName: 'Asdf, Qwerty'};
                c.initLoggedInUser({ displayName: 'Xyz, Abc', isStaff: true } as any as UserIdAndPermissions);
                expect(c.selectedName.value).toEqual(c.defaultedStaff);
                expect(c.handleSelectedNameValueChange).toHaveBeenCalled();
            });
            it('should not redefault staff if not allowed', () => {
                jest.spyOn(c, 'handleSelectedNameValueChange');
                c.ngOnInit();
                c.canFunctionAsOtherStaff = false;
                c.defaultedStaff = { key: -100, displayName: 'Asdf, Qwerty' };
                c.initLoggedInUser({ displayName: 'Xyz, Abc', isStaff: true } as any as UserIdAndPermissions);
                expect(c.selectedName.value).toEqual({ displayName: 'Xyz, Abc' });
                expect(c.handleSelectedNameValueChange).toHaveBeenCalled();
            });
        });
    });

    describe('on selected name change', () => {
        beforeEach(() => {
            userInfo.userDetails$ = of({ staffId: 123, displayName: 'abc', isStaff: true });
            c.ngOnInit();
            c.ngAfterViewInit();
        });

        it('calls to get permissions', fakeAsync(() => {
            c.selectedName.setValue({ key: 100, displayName: 'a' });
            tick(100);
            expect(timeService.getUserPermissions).toHaveBeenCalledWith(100);
            expect(userInfo.setUserDetails.mock.calls[0][0].staffId).toBe(100);
            expect(userInfo.setUserDetails.mock.calls[0][0].displayName).toBe('a');
            expect(userInfo.setUserDetails.mock.calls[0][0].permissions).toEqual({});
        }));

        it('displays error message and sets error if no permissions', fakeAsync(() => {
            jest.spyOn(c.selectedName, 'setErrors');
            timeService.getUserPermissions = jest.fn().mockReturnValue(of(new TimeRecordingPermissions()));

            c.selectedName.setValue({ key: 100 });
            tick(100);

            expect(notificationService.openAlertModal).toHaveBeenCalled();
            expect(c.selectedName.setErrors).toHaveBeenCalled();
        }));

        it('emits staffId change event with permissions', fakeAsync(() => {
            const permissions = { ...new TimeRecordingPermissions(), canRead: true, canInsert: true };
            timeService.getUserPermissions = jest.fn().mockReturnValue(of(permissions));

            c.selectedName.setValue({ key: 100 });
            tick(100);

            expect(c.selectedName.valid).toBeTruthy();
            expect(c.selectedName.errors).toBeNull();
            expect(userInfo.setUserDetails.mock.calls[0][0].staffId).toBe(100);
            expect(userInfo.setUserDetails.mock.calls[0][0].permissions).toEqual(permissions);

            c.selectedName.setValue({ key: 0 });
            tick(100);

            expect(c.selectedName.valid).toBeTruthy();
            expect(c.selectedName.errors).toBeNull();
            expect(userInfo.setUserDetails.mock.calls[1][0].staffId).toBe(0);
            expect(userInfo.setUserDetails.mock.calls[1][0].permissions).toEqual(permissions);
        }));

        it('resets errors on change', fakeAsync(() => {
            timeService.getUserPermissions = jest.fn().mockReturnValue(of(new TimeRecordingPermissions()));
            c.selectedName.setValue({ key: 100 });
            tick(100);
            expect(c.selectedName.valid).toBeFalsy();
            expect(c.selectedName.errors).not.toBeNull();

            c.selectedName.setValue(null);
            tick(100);
            expect(c.selectedName.errors.required).toBeTruthy();
        }));
    });
});