import { fakeAsync, flushMicrotasks, tick } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { TimeRecordingPermissions } from '../time-recording-model';
import { UserInfoServiceMock } from '../time-recording.mock';
import { TimeSettingsService } from './time-settings.service';

describe('Service: USettings', () => {
    let httpClient: HttpClientMock;
    let userInfo: UserInfoServiceMock;
    let service: TimeSettingsService;

    beforeEach(() => {
        httpClient = new HttpClientMock();
        userInfo = new UserInfoServiceMock();
        service = new TimeSettingsService(httpClient as any, userInfo as any);
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });

    it('should call server to get view data', fakeAsync(() => {
        const viewData = { userInfo: { nameId: 100 }, settings: { addEntryOnSave: true } };
        httpClient.get = jest.fn().mockReturnValue(of(viewData));
        service.getViewData$();
        flushMicrotasks();

        expect(httpClient.get).toHaveBeenCalledWith('api/accounting/time/view');
    }));

    it('should initialise settings', done => {
        const viewData = { userInfo: {}, settings: { valueTimeOnEntry: true, unitsPerHour: 10, continueFromCurrentTime: true, wipSplitMultiDebtor: true } };
        httpClient.get = jest.fn().mockReturnValue(of(viewData));
        service.getViewData$().subscribe(() => {

            expect(service.valueTimeOnEntry).toBeTruthy();
            expect(service.unitsPerHour).toEqual(10);
            expect(service.continueFromCurrentTime).toBeTruthy();
            expect(service.wipSplitMultiDebtor).toBeTruthy();

            done();
        });
    });

    it('should initialise user info for staff', fakeAsync(() => {
        const viewData = { settings: {}, userInfo: { nameId: 10, displayName: 'Donald', isStaff: true, canAdjustValues: true, canFunctionAsOtherStaff: true } };
        httpClient.get = jest.fn().mockReturnValue(of(viewData));
        service.canFunctionAsOtherStaff.subscribe((d) => {
            expect(d).toBeTruthy();
        });

        service.getViewData$().subscribe(() => {
            const permissions = new TimeRecordingPermissions();
            Object.keys(permissions).forEach(v => permissions[v] = true);
            expect(userInfo.setUserDetails.mock.calls[0][0].staffId).toBe(10);
            expect(userInfo.setUserDetails.mock.calls[0][0].displayName).toBe('Donald');
            expect(userInfo.setUserDetails.mock.calls[0][0].permissions).toEqual(permissions);
        });
        tick();
    }));

    it('should not grant permissions for non staff', fakeAsync(() => {
        const viewData = { settings: {}, userInfo: { nameId: -1, displayName: 'Non-Staff User', isStaff: false, canAdjustValues: true, canFunctionAsOtherStaff: true } };
        httpClient.get = jest.fn().mockReturnValue(of(viewData));
        service.canFunctionAsOtherStaff.subscribe((d) => {
            expect(d).toBeTruthy();
        });

        service.getViewData$().subscribe(() => {
            const permissions = new TimeRecordingPermissions();
            Object.keys(permissions).forEach(v => permissions[v] = false);
            expect(userInfo.setUserDetails.mock.calls[0][0].staffId).toBe(-1);
            expect(userInfo.setUserDetails.mock.calls[0][0].displayName).toBe('Non-Staff User');
            expect(userInfo.setUserDetails.mock.calls[0][0].permissions).toEqual(permissions);
        });
        tick();
    }));

    it('should set userTaskSecurity', done => {
        const viewData = { settings: {}, userInfo: { nameId: 10, displayName: 'Donald', maintainPostedTimeEdit: true, maintainPostedTimeDelete: false } };
        httpClient.get = jest.fn().mockReturnValue(of(viewData));

        service.getViewData$().subscribe(() => {
            expect(service.userTaskSecurity.maintainPostedTime.edit).toBeTruthy();
            expect(service.userTaskSecurity.maintainPostedTime.delete).toBeFalsy();

            done();
        });
    });

    it('should evaluate time format', fakeAsync(() => {
        const viewData = { userInfo: {}, settings: { displaySeconds: true, is12HourFormat: false } };
        httpClient.get = jest.fn().mockReturnValue(of(viewData));

        service.displaySecondsOnChange.subscribe((d) => {
            expect(d).toBeTruthy();
        });
        service.getViewData$().subscribe(() => {
            expect(service.displaySeconds).toBeTruthy();
            expect(service.timeFormat).toEqual('HH:mm:ss');
        });

        tick();
    }));

    it('should set the seconds and time format correctly', () => {
        const displaySecondsChangeSpy = jest.spyOn(service.displaySecondsOnChange, 'next');
        service.changeSettings(true, false);
        expect(service.displaySeconds).toBeTruthy();
        expect(service.is12HourFormat).toBeFalsy();
        expect(service.timeFormat).toBe('HH:mm:ss');
        expect(displaySecondsChangeSpy).toHaveBeenCalled();
    });
});