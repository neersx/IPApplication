import { PriorArtServiceMock } from 'cases/prior-art/priorart.service.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { StateServiceMock } from 'mocks/state-service.mock';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { PriorartMaintenanceHelper } from '../priorart-maintenance-helper';
import { CitationsListComponent } from './citations-list.component';

describe('CitationsListComponent', () => {

    const service = new PriorArtServiceMock();
    const cdRef = new ChangeDetectorRefMock();
    const notificationService = new NotificationServiceMock();
    const ipxNotificationService = new IpxNotificationServiceMock();
    let stateService = new StateServiceMock();
    let component: CitationsListComponent;

    beforeEach(() => {
        stateService = new StateServiceMock();
        component = new CitationsListComponent(service as any, cdRef as any, stateService as any, { keys: { priorart: { citationsListPageSize: jest.fn() } } } as any, notificationService as any, ipxNotificationService as any);
        component.grid = new IpxKendoGridComponentMock() as any;
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));

    describe('Initialising', () => {
        it('should build and populate the grid', () => {
            component.sourceData = { sourceId: 123, isSourceDocument: false };
            component.ngOnInit();
            expect(component.gridOptions).toBeDefined();
        });

        it('should build and populate the grid for prior art', () => {
            component.sourceData = { sourceId: 123, isSourceDocument: false };
            component.ngOnInit();
            expect(component.gridOptions).toBeDefined();
            component.gridOptions.read$();
            expect(service.getCitations$).toHaveBeenCalled();
            expect(service.getCitations$.mock.calls[0][0].sourceDocumentId).toBe(123);
            expect(service.getCitations$.mock.calls[0][0].isSourceDocument).toBe(false);
        });

        it('should build and populate the grid for source document', () => {
            component.sourceData = { sourceId: 555, isSourceDocument: true };
            component.ngOnInit();
            expect(component.gridOptions).toBeDefined();
            component.gridOptions.read$();
            expect(service.getCitations$).toHaveBeenCalled();
            expect(service.getCitations$.mock.calls[1][0].sourceDocumentId).toBe(555);
            expect(service.getCitations$.mock.calls[1][0].isSourceDocument).toBe(true);
        });
    });

    describe('launchSearch', () => {
        it('should change states correctly', () => {
            stateService.go = jest.fn();
            stateService.params = { caseKey: 333, sourceId: 123 };
            component.sourceData = { sourceId: 123, isSourceDocument: false };
            component.launchSearch();
            expect(component.stateService.go).toHaveBeenCalledWith('priorArt', { caseKey: 333, showCloseButton: true, sourceId: 123 });
        });
    });

    describe('deleteCitation', () => {
        it('should call the delete service correctly when source is being maintained', () => {
            const dataItem = {id: 333};
            component.sourceData = { sourceId: 555, isSourceDocument: true };
            ipxNotificationService.openConfirmationModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } });
            service.deleteCitation$ = jest.fn().mockReturnValue(of({result: true}));
            component.deleteCitation(dataItem);
            expect(service.deleteCitation$).toHaveBeenCalledWith(555, dataItem.id);
            expect(component.grid.search).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
        });

        it('should call the delete service correctly when source is not being maintained', () => {
            const dataItem = {id: 333};
            component.sourceData = { sourceId: 555, isSourceDocument: false };
            ipxNotificationService.openConfirmationModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } });
            service.deleteCitation$ = jest.fn().mockReturnValue(of({result: true}));
            component.deleteCitation(dataItem);
            expect(service.deleteCitation$).toHaveBeenCalledWith(dataItem.id, 555);
            expect(component.grid.search).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
        });
    });

    describe('editCitation', () => {
        it('should call the open maintenance window correctly edit button clicked', () => {
            spyOn(PriorartMaintenanceHelper, 'openMaintenance');
            const dataItem = {
                dataItem: {
                    sourceId: 333
                }
            };
            stateService.params = { caseKey: 333 };
            component.editCitation(dataItem);
            expect(PriorartMaintenanceHelper.openMaintenance).toHaveBeenCalledWith(dataItem.dataItem, 333);
        });
    });
});