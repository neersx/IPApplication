import { TimeRecordingPermissions, UserIdAndPermissions } from '../time-recording-model';
import { UserInfoService } from './user-info.service';

describe('Service: UserInfo', () => {
    it('should create an instance', () => {
        const service = new UserInfoService(null);
        expect(service).toBeTruthy();
    });
});

describe('Setting user details', () => {
    const pageTitleService = { setPrefix: jest.fn() };
    let service: UserInfoService;
    beforeEach(() => {
        service = new UserInfoService(pageTitleService as any);
    });

    it('prefixes the staff name to the title', () => {
        service.setUserDetails({ staffId: -5552368, displayName: 'Name, Staff', permissions: new TimeRecordingPermissions() });
        expect(pageTitleService.setPrefix).toHaveBeenCalledWith('Name, Staff');
    });

    it('should return the details of the selected user', done => {
        const userDetails = { staffId: -5552368, displayName: 'Name, Staff', permissions: new TimeRecordingPermissions() };
        service.setUserDetails(userDetails);

        service.userDetails$.subscribe((ud) => {
            expect(ud).toEqual(userDetails);
            done();
        });
    });

    it('should rememeber the logged in user name id', () => {
        const userDetails = { staffId: -5552368, displayName: 'Name, Staff', permissions: new TimeRecordingPermissions() };
        service.setUserDetails(userDetails);

        expect(service.loggedInUserNameId).toEqual(userDetails.staffId);
    });

    it('should return true, indicating if the selected user is same as logged in user', done => {
        const userDetails = { staffId: -5552368, displayName: 'Name, Staff', permissions: new TimeRecordingPermissions() };
        service.setUserDetails(userDetails);

        service.isLoggedInUser$.subscribe((isLoggedIn) => {
            expect(isLoggedIn).toBeTruthy();

            done();
        });
        service.userDetailsSubject.subscribe((userData) => {
            expect(userData.permissions.canAddTimer).toBeTruthy();
            done();
        });
    });

    it('should return false, indicating the selected user is not same as logged in user', done => {
        const userDetails = { staffId: -5552368, displayName: 'Name, Staff', permissions: new TimeRecordingPermissions() };
        service.setUserDetails(userDetails);
        service.setUserDetails({ staffId: 100, displayName: 'Humpty', permissions: new TimeRecordingPermissions() });

        service.isLoggedInUser$.subscribe((isLoggedIn) => {
            expect(isLoggedIn).toBeFalsy();

            done();
        });
        service.userDetailsSubject.subscribe((userData) => {
            expect(userData.permissions.canAddTimer).toBeFalsy();
            done();
        });
    });
});
