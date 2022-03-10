import { fakeAsync, tick } from '@angular/core/testing';
import { LinkType } from 'cases/prior-art/priorart-model';
import { PriorArtServiceMock } from 'cases/prior-art/priorart.service.mock';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { AddLinkedCasesComponent } from '../linked-cases/add-linked-cases/add-linked-cases.component';
import { FamilyCaselistNameComponent } from './family-caselist-name.component';

describe('FamilyCaselistNameComponent', () => {

    const service = new PriorArtServiceMock();
    let component: FamilyCaselistNameComponent;
    let notificationService: any;
    let ipxNotificationService: any;
    let translateService: any;
    let modalService: any;

    beforeEach(() => {
        notificationService = new NotificationServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        ipxNotificationService.openConfirmationModal.mockReturnValue({ content: { confirmed$: of(true) } });
        translateService = { instant: jest.fn().mockReturnValue('translated-message')};
        modalService = new ModalServiceMock();
        modalService = {
            openModal: jest.fn().mockReturnValue(
                {
                    content: {
                        success$: of(true)
                    }
                })
        };
        component = new FamilyCaselistNameComponent(service as any, { keys: { priorart: { linkedFamilyCaseListGrid: jest.fn() } } } as any, notificationService, ipxNotificationService, translateService, modalService);
        component.subscribeToUpdates = jest.fn();
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));

    describe('initialising', () => {
        it('should build and populate the family case list and name grids', () => {
            component.sourceData = { sourceId: 2345784587 };
            component.ngOnInit();
            expect(component.familyGridOptions).toBeDefined();
            expect(component.nameGridOptions).toBeDefined();
            component.familyGridOptions.read$();
            expect(service.getFamilyCaseList$).toHaveBeenCalled();
            expect(service.getFamilyCaseList$.mock.calls[0][0]).toBe(2345784587);
            component.nameGridOptions.read$();
            expect(service.getLinkedNameList$).toHaveBeenCalled();
            expect(service.getLinkedNameList$.mock.calls[0][0]).toBe(2345784587);
        });
    });

    describe('refreshGrid', () => {
        it('should refresh all grids on the page', () => {
            component.sourceData = { sourceId: 2345784587, isSourceDocument: true };
            component.ngOnInit();
            component.familyGridOptions._search = jest.fn();
            component.nameGridOptions._search = jest.fn();
            component.refreshGrid();
            expect(component.familyGridOptions._search).toHaveBeenCalled();
            expect(component.nameGridOptions._search).toHaveBeenCalled();
        });
    });

    describe('countGrids', () => {
        it('should add the counts correctly', () => {
            component.sourceData = { sourceId: 2345784587, isSourceDocument: true };
            component.ngOnInit();
            component.familyGridCount = 20;
            component.nameGridCount = 2;
            expect(component.countGrids()).toEqual(22);
        });
    });

    describe('removing linked case list, family or name', () => {
        const title = 'priorart.maintenance.step4.removeLink.title';
        const message = 'priorart.maintenance.step4.removeLink.confirm.';
        beforeEach(() => {
            component.sourceData = {sourceId: 101};
            component.subscribeToUpdates = jest.fn();
        });
        it('displays confirmation for family and calls service', fakeAsync(() => {
            component.deleteRecord({isFamily: true, id: -5678});
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalledWith(title, message + 'family', 'Yes', 'No', null, { forSource: '' });
            tick();
            expect(service.removeAssociation$).toHaveBeenCalledWith(LinkType.Family, 101, -5678);
            tick();
            expect(notificationService.success).toHaveBeenCalled();
            expect(service.hasUpdatedAssociations$.next).toHaveBeenCalledWith(true);
        }));
        it('displays confirmation for case list and calls service', fakeAsync(() => {
            component.deleteRecord({ isFamily: false, id: -6789 });
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalledWith(title, message + 'caseList', 'Yes', 'No', null, { forSource: '' });
            tick();
            expect(service.removeAssociation$).toHaveBeenCalledWith(LinkType.CaseList, 101, -6789);
            tick();
            expect(notificationService.success).toHaveBeenCalled();
            expect(service.hasUpdatedAssociations$.next).toHaveBeenCalledWith(true);
        }));
        it('displays confirmation for name and calls service', fakeAsync(() => {
            component.deleteRecord({ isFamily: false, id: -7890, nameNo: 555 });
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalledWith(title, message + 'name', 'Yes', 'No', null, {forSource: ''});
            tick();
            expect(service.removeAssociation$).toHaveBeenCalledWith(LinkType.Name, 101, -7890);
            tick();
            expect(notificationService.success).toHaveBeenCalled();
            expect(service.hasUpdatedAssociations$.next).toHaveBeenCalledWith(true);
        }));
        it('displays additional information for source documents', fakeAsync(() => {
            component.sourceData.isSourceDocument = true;
            component.deleteRecord({ isFamily: false, id: -7890, nameNo: 555 });
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalledWith(title, message + 'name', 'Yes', 'No', null, { forSource: 'translated-message' });
            tick();
            expect(service.removeAssociation$).toHaveBeenCalledWith(LinkType.Name, 101, -7890);
            tick();
            expect(notificationService.success).toHaveBeenCalled();
            expect(service.hasUpdatedAssociations$.next).toHaveBeenCalledWith(true);
        }));
    });

    describe('linkCases', () => {
        it('should open the modal and refresh on success', fakeAsync(() => {
            component.sourceData = { data: {sourceId: 1234, id: -555}};
            component.linkCases();

            expect(modalService.openModal.mock.calls[0][0]).toBe(AddLinkedCasesComponent);
            expect(modalService.openModal.mock.calls[0][1]).toEqual(expect.objectContaining({ initialState: { sourceData: component.sourceData, invokedFromCases: false } }));
            tick();
            expect(service.hasUpdatedAssociations$.next).toHaveBeenCalledWith(true);
        }));
    });
});