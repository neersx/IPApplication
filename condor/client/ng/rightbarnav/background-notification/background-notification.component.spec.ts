import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { ChangeDetectorRefMock, NotificationServiceMock, StateServiceMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { BackgroundNotificationComponent } from './background-notification.component';
import { BackgroundNotificationMessage, ProcessSubType, ProcessType, StatusType } from './background-notification.service';
import { BackgroundNotificationServiceMock } from './background-notification.service.mock';

describe('BackgroundNotificationComponent', () => {
    let component: BackgroundNotificationComponent;
    let backgroundNotificationServiceMock: any;
    let notificationServiceMock: NotificationServiceMock;
    let translateServiceMock: TranslateServiceMock;
    let stateServiceMock: StateServiceMock;
    let commonUtilityServiceMock: CommonUtilityServiceMock;
    let modalService: any;
    const graphIntegrationService = { login: jest.fn() };

    beforeEach((() => {
        translateServiceMock = new TranslateServiceMock();
        commonUtilityServiceMock = new CommonUtilityServiceMock();
        stateServiceMock = new StateServiceMock();
        backgroundNotificationServiceMock = new BackgroundNotificationServiceMock();
        notificationServiceMock = new NotificationServiceMock();
        modalService = { openModal: jest.fn() };
        component = new BackgroundNotificationComponent(new ChangeDetectorRefMock() as any, backgroundNotificationServiceMock, notificationServiceMock as any,
            stateServiceMock as any, translateServiceMock as any, commonUtilityServiceMock as any, graphIntegrationService as any, modalService);
    }));

    it('should component initialize', () => {
        expect(component).toBeTruthy();
        expect(component.gridoptions).toBeDefined();
        expect(component.gridoptions.columns.length).toEqual(5);
    });

    it('detect changes should be called on afterviewInit', () => {
        component.ngAfterViewInit();
        expect(component.cdref.detectChanges).toHaveBeenCalled();
    });

    it('delete notification messages is called', () => {
        const processIds = [1, 2];
        component.notificationService.confirmDelete = jest.fn().mockReturnValue(of().toPromise());
        component.deleteProcess(processIds);
        expect(component.notificationService.confirmDelete).toHaveBeenCalled();
    });

    it('handle click when GlobalCaseChange item is clicked', () => {
        component.translate.instant = jest.fn().mockReturnValue('');
        component.stateService.go = jest.fn();
        component.callBack = jest.fn();
        const message = new BackgroundNotificationMessage(
            1,
            1,
            'Global Field Update',
            new Date(),
            null,
            StatusType.Completed.toString(),
            '',
            ProcessType[ProcessType.GlobalCaseChange].toString(),
            null
        );
        component.handleClick(message);
        expect(component.stateService.go).toHaveBeenCalled();
        expect(component.translate.instant).toHaveBeenCalledWith('backgroundNotifications.title.bulkFieldUpdateResults');
        expect(component.callBack).toHaveBeenCalled();
    });
    it('handle click when Bulk policing item is clicked', () => {
        component.translate.instant = jest.fn().mockReturnValue('backgroundNotifications.title.policing');
        component.stateService.go = jest.fn();
        component.callBack = jest.fn();
        const message = new BackgroundNotificationMessage(
            1,
            1,
            'Bulk Policing',
            new Date(),
            null,
            StatusType.Completed.toString(),
            '',
            ProcessType[ProcessType.GlobalCaseChange].toString(),
            ProcessSubType[ProcessSubType.Policing].toString()
        );
        component.handleClick(message);
        expect(component.translate.instant).toHaveBeenCalledWith('backgroundNotifications.title.policing');
        expect(component.stateService.go).toHaveBeenCalledWith('search-results', {
            presentationType: 'GlobalCaseChangeResults',
            globalProcessKey: message.processId,
            backgroundProcessResultTitle: 'backgroundNotifications.title.policing',
            queryContext: 2
        }, { inherit: false });
        expect(component.callBack).toHaveBeenCalled();
    });

    it('verify loginGraphIntegration', () => {
        const dataItem = { identityId: 45, processId: 11 };
        component.loginGraphIntegration(dataItem);
        expect(graphIntegrationService.login).toHaveBeenCalledWith(dataItem);
    });
    it('cannot show link when sub process is GlobalNameChange', () => {
        const dataItem = { identityId: 45, processId: 11, processType: 'globalNameChange', status: 'Completed' };
        const result = component.canShowLink(dataItem);
        expect(result).toBeFalsy();
    });
    it('cannot show link when sub process is ApplyRecordals', () => {
        const dataItem = { identityId: 45, processId: 11, processSubType: 'applyRecordals', status: 'Completed' };
        const result = component.canShowLink(dataItem);
        expect(result).toBeFalsy();
    });
    it('canShowLink should be true when process is completed', () => {
        const dataItem = { identityId: 45, processId: 11, status: 'Completed' };
        const result = component.canShowLink(dataItem);
        expect(result).toBeTruthy();
    });

    describe('display time posting results', () => {
        it('should display the modal', () => {
            const statusInfo = '{"rowsPosted":100,"rowsIncomplete":10,"hasOfficeEntityError":false,"hasError":false,"hasWarning":false,"error":null}';
            component.displayTimePostingResults(statusInfo);
            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.mock.calls[0][1].initialState).toEqual(expect.objectContaining({ rowsPosted: 100, rowsIncomplete: 10, hasOfficeEntityError: false, hasError: false, hasWarning: false, error: null }));
        });
    });
});