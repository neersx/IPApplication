import { LocalSettings } from 'core/local-settings';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { GridNavigationServiceMock, IpxNotificationServiceMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { TaxCodeMock } from 'mocks/tax-code.mock';
import { TaxCodeDetailsComponent } from './tax-code-details.component';

describe('TaxCodeDetailsComponent', () => {
    let component: TaxCodeDetailsComponent;
    const service = new TaxCodeMock();
    const stateService = new StateServiceMock();
    const gridNavigationService = new GridNavigationServiceMock();
    const notificationServiceMock = new IpxNotificationServiceMock();
    const notificationService = new NotificationServiceMock();
    const translateService = { instant: jest.fn() };
    let localSettings: LocalSettings;
    beforeEach(() => {
        localSettings = new LocalSettingsMock();
        component = new TaxCodeDetailsComponent(service as any, stateService as any,
            gridNavigationService as any, notificationServiceMock as any, notificationService as any,
            translateService as any, localSettings as any);
            component.stateParams = { id: 1, rowKey: '1' };
            component.navData = {
            keys: [{ key: '1', value: '10' }, { key: '1', value: '11' }],
            totalRows: 1,
            pageSize: 0,
            fetchCallback: jest.fn()
        };
    });
    it('should initialize TaxCodeDetailsComponent', () => {
        expect(component).toBeTruthy();
    });
    it('should call ngOnInit to check hasPreviousState', () => {
        component.ngOnInit();
        expect(component.hasPreviousState).toEqual(true);
    });
    it('should call  ngOnInit load topic', () => {
        component.ngOnInit();
        expect(component.topicOptions.topics.length).toEqual(2);
    });
    it('should call  delete', () => {
        component.delete();
        expect(notificationServiceMock.openDeleteConfirmModal).toHaveBeenCalled();
    });
    it('should call  navigateToNext', () => {
        component.navigateToNext();
        expect(stateService.go).toBeCalled();
    });
    it('should call  onSave', () => {
        component.ngOnInit();
        for (const row of component.topicOptions.topics) {
            Object.assign(row, {
                getFormData: jest.fn(),
                isDirty: jest.fn().mockReturnValue(true)
            });
        }
        component.onSave();
        expect(service.updateTaxCodeDetails).toHaveBeenCalled();
    });
    it('should call  revert', () => {
        component.ngOnInit();
        for (const row of component.topicOptions.topics) {
            Object.assign(row, {
                getFormData: jest.fn(),
                isDirty: jest.fn().mockReturnValue(true)
            });
        }
        component.revert();
        expect(notificationServiceMock.openDiscardModal).toHaveBeenCalled();
    });

});