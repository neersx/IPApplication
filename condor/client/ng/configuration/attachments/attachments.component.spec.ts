import { ChangeDetectorRefMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { AttachmentConfigurationServiceMock } from './attachments-configuration.service.mock';
import { AttachmentsComponent } from './attachments.component';

describe('AttachmentsComponent', () => {
    let component: (viewData: any) => AttachmentsComponent;
    let stateService: StateServiceMock;
    let notificationService: NotificationServiceMock;
    let cdr: ChangeDetectorRefMock;
    let service: AttachmentConfigurationServiceMock;

    beforeEach(() => {
        stateService = new StateServiceMock();
        notificationService = new NotificationServiceMock();
        cdr = new ChangeDetectorRefMock();
        service = new AttachmentConfigurationServiceMock();
        component = (viewData: any) => {
            const c = new AttachmentsComponent(stateService as any, notificationService as any, cdr as any, service as any);
            c.viewInitialiser = {
                viewData
            };
            c.ngOnInit();

            return c;
        };
    });

    it('should initialise', () => {
        const viewData = {
            settings: {
                storageLocations: []
            }
        };
        const c = component(viewData);
        expect(c.save).toBeDefined();
        expect(c.isSaveEnabled).toBeDefined();
        expect(c.isDiscardEnabled).toBeDefined();
        expect(c.topicOptions).toBeDefined();
    });

    it('should save with storage locations', () => {
        const viewData = {
            settings: {
                storageLocations: []
            }
        };
        const c = component(viewData);
        c.topicOptions.topics[0].getDataChanges = (): { [key: string]: any } => {
            return {
                storageLocations: [{ storageLocationId: 0 }, { storageLocationId: 1 }]
            };
        };
        c.topicOptions.topics[1].getDataChanges = (): { [key: string]: any } => {
            return {
                networkDrives: [{ networkDriveMappingId: 0 }, { networkDriveMappingId: 1 }]
            };
        };
        c.save();
        expect(c.isSaveEnabled).toEqual(false);
        expect(service.save$).toHaveBeenCalledWith({
            storageLocations: [{ storageLocationId: 0 }, { storageLocationId: 1 }],
            networkDrives: [{ networkDriveMappingId: 0 }, { networkDriveMappingId: 1 }]
        });

        service.save$().subscribe(() => {
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();
        });
    });

    it('should not show dms warning message without changes', () => {
        const viewData = {
            settings: {
                storageLocations: []
            }
        };
        const c = component(viewData);
        c.topicOptions.topics[0].getDataChanges = (): { [key: string]: any } => {
            return {
                storageLocations: [{ storageLocationId: 0 }, { storageLocationId: 1 }]
            };
        };
        c.save();

        expect(c.isSaveEnabled).toEqual(false);
        expect(notificationService.openConfirmationModal).not.toHaveBeenCalled();
    });
});