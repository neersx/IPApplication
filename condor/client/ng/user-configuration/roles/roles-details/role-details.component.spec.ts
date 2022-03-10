import { LocalSettings } from 'core/local-settings';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { GridNavigationServiceMock, IpxNotificationServiceMock, NotificationServiceMock, RoleSearchMock, StateServiceMock } from 'mocks';
import { RoleDetailsComponent } from './role-details.component';
describe('RoleDetailComponent', () => {
    let c: RoleDetailsComponent;
    const service = new RoleSearchMock();
    const gridNavigationService = new GridNavigationServiceMock();
    const stateService = new StateServiceMock();
    const notificationServiceMock = new IpxNotificationServiceMock();
    const notificationService = new NotificationServiceMock();
    const translateService = { instant: jest.fn() };
    let localSettings: LocalSettings;
    beforeEach(() => {
        localSettings = new LocalSettingsMock();
        c = new RoleDetailsComponent(service as any, gridNavigationService as any, stateService as any, notificationServiceMock as any,
            notificationService as any, translateService as any, localSettings);
        c.stateParams = { id: 1, rowKey: '1' };
        c.viewData = { canDeleteRole: true };
        c.navData = {
            keys: [{ key: '1', value: '10' }, { key: '1', value: '11' }],
            totalRows: 1,
            pageSize: 0,
            fetchCallback: jest.fn()
        };
    });
    it('should initialize RoleDetailComponent', () => {
        expect(c).toBeTruthy();
    });
    it('should call ngOnInit to check isShowDelete', () => {
        c.ngOnInit();
        expect(c.isShowDelete).toEqual(true);
        c.stateParams.id = -20;
        c.ngOnInit();
        expect(c.isShowDelete).toEqual(false);
    });
    it('should call ngOnInit to check hasPreviousState', () => {
        c.ngOnInit();
        expect(c.hasPreviousState).toEqual(true);
    });
    it('should call  ngOnInit load topic', () => {
        c.ngOnInit();
        expect(c.options.topics.length).toEqual(4);
    });
    it('should call  deleteRole', () => {
        c.deleteRole();
        expect(notificationServiceMock.openDeleteConfirmModal).toHaveBeenCalled();
    });
    it('should call  navigateToNext', () => {
        c.navigateToNext();
        expect(stateService.go).toBeCalled();
    });
    it('should call  revert', () => {
        c.ngOnInit();
        for (const row of c.options.topics) {
            Object.assign(row, {
                getFormData: jest.fn(),
                isDirty: jest.fn().mockReturnValue(true)
            });
        }
        c.revert();
        expect(notificationServiceMock.openDiscardModal).toHaveBeenCalled();
    });
    it('should call  onSave', () => {
        c.ngOnInit();
        for (const row of c.options.topics) {
            Object.assign(row, {
                getFormData: jest.fn(),
                isDirty: jest.fn().mockReturnValue(true)
            });
        }
        c.onSave();
        expect(service.updateRoleDetails).toHaveBeenCalled();
    });
});