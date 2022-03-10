import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock, StateServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { DmsIntegrationComponent } from './dms-integration.component';
import { DmsIntegrationServiceMock } from './dms-integration.service.mock';

describe('Inprotech.Configuration.DMSIntegration', () => {
    let component: (viewData: any) => DmsIntegrationComponent;
    let service: DmsIntegrationServiceMock;
    let notificationService: NotificationServiceMock;
    let stateService: StateServiceMock;
    let cdr: ChangeDetectorRefMock;
    let translateService: TranslateServiceMock;
    let modalService: ModalServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;

    beforeEach(() => {
        service = new DmsIntegrationServiceMock();
        notificationService = new NotificationServiceMock();
        stateService = new StateServiceMock();
        cdr = new ChangeDetectorRefMock();
        translateService = new TranslateServiceMock();
        modalService = new ModalServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        component = (viewData: any) => {
            const c = new DmsIntegrationComponent(service as any, notificationService as any, stateService as any, cdr as any, translateService as any, modalService as any, ipxNotificationService as any);
            c.viewInitialiser = {
                viewData
            };
            c.items = [];
            c.ngOnInit();

            return c;
        };
    });

    it('should initialise', () => {
        const viewData = {
            dataDownload: [],
            iManage: []
        };
        const c = component(viewData);
        expect(c.items).toEqual(viewData.dataDownload);
        expect(c.save).toBeDefined();
        expect(c.isSaveEnabled).toBeDefined();
        expect(c.isDiscardEnabled).toBeDefined();
        expect(c.topicOptions).toBeDefined();
    });

    it('should save with databases settings', () => {
        modalService.openModal.mockReturnValue({
            content: {
                onClose$: of(true)
            }
        } as any);
        service.hasPendingDatabaseChanges$.next(true);
        const viewData = {
            dataDownload: [],
            iManage: []
        };
        const c = component(viewData);
        c.topicOptions.topics[0].topics[0].getDataChanges = (): { [key: string]: any } => {
            return {
                Databases: [{ siteDbId: 0 }, { siteDbId: 1 }]
            };
        };
        c.save();
        service.testConnections$().then(() => {
            expect(c.isSaveEnabled).toEqual(false);

            expect(service.save$).toHaveBeenCalled();
            expect(service.testConnections$).toHaveBeenCalled();
            service.save$().subscribe(() => {
                expect(notificationService.success).toHaveBeenCalled();
                expect(stateService.reload).toHaveBeenCalled();
            });
        });
    });

    it('should not save with empty databases settings', () => {
        modalService.openModal.mockReturnValue({
            content: {
                onClose$: of(true)
            }
        } as any);
        service.testConnections$.mockReturnValue(of(false));
        service.hasPendingDatabaseChanges$.next(true);
        const viewData = {
            dataDownload: [],
            iManage: []
        };
        const c = component(viewData);
        c.topicOptions.topics[0].topics[1].hasChanges = true;
        c.save();

        expect(c.isSaveEnabled).toEqual(false);
        expect(service.save$).not.toHaveBeenCalled();
        expect(notificationService.alert).toHaveBeenCalled();
    });

    it('should not show dms warning message without changes', () => {
        modalService.openModal.mockReturnValue({
            content: {
                onClose$: of(true)
            }
        } as any);
        service.testConnections$.mockReturnValue(of(false));
        service.hasPendingDatabaseChanges$.next(false);
        const viewData = {
            dataDownload: [],
            iManage: []
        };
        const c = component(viewData);
        c.topicOptions.topics[0].topics[0].getDataChanges = (): { [key: string]: any } => {
            return {
                Databases: [{ siteDbId: 0 }, { siteDbId: 1 }]
            };
        };
        c.save();

        expect(c.isSaveEnabled).toEqual(false);
        expect(notificationService.openConfirmationModal).not.toHaveBeenCalled();
        expect(service.testConnections$).not.toHaveBeenCalled();
    });

    it('should not call test connection without changes', () => {
        modalService.openModal.mockReturnValue({
            content: {
                onClose$: of(true)
            }
        } as any);
        service.testConnections$.mockReturnValue(of(false));
        service.hasPendingDatabaseChanges$.next(false);
        const viewData = {
            dataDownload: [],
            iManage: []
        };
        const c = component(viewData);
        c.topicOptions.topics[0].topics[0].getDataChanges = (): { [key: string]: any } => {
            return {
                Databases: [{ siteDbId: 0 }, { siteDbId: 1 }]
            };
        };
        c.save();

        expect(c.isSaveEnabled).toEqual(false);
        expect(service.save$).toHaveBeenCalled();
        expect(service.testConnections$).not.toHaveBeenCalled();
    });

    it('should not open the modal if toggle is on', () => {
        const viewData = {
            dataDownload: [],
            iManage: []
        };
        const c = component(viewData);
        jest.spyOn(c, 'finalSave');
        c.isImanageEnabled = true;
        c.save();
        expect(c.finalSave).toBeCalled();
    });
});