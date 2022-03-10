import { TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks/notification-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { OfficeMaintenanceComponent } from './office-maintenance/office-maintenance.component';
import { OfficeComponent } from './offices.component';
import { OfficeServiceMock } from './offices.service.mock';

describe('Inprotech.Configuration.Offices', () => {
    let component: OfficeComponent;
    let service: OfficeServiceMock;
    let modalService: ModalServiceMock;
    let translateService: TranslateServiceMock;
    let notificationService: NotificationServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;

    beforeEach(() => {
        service = new OfficeServiceMock();
        modalService = new ModalServiceMock();
        notificationService = new NotificationServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        translateService = new TranslateServiceMock();
        component = new OfficeComponent(service as any, modalService as any, notificationService as any, ipxNotificationService as any, translateService as any);
        component.viewData = {
            canDelete: true,
            canAdd: true,
            canEdit: true
        };
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
        component._resultsGrid.wrapper = {
            data: [
                { rowKey: '123^11', steps: [{ step1: true, step2: false }] },
                { rowKey: '123^12', steps: [{ step1: true, step2: false }] }
            ]
        } as any;
    });

    it('should initialise', () => {
        component.ngOnInit();
        spyOn(component, 'buildGridOptions');

        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.columns.length).toBe(4);
        expect(component.gridOptions.columns[0].title).toBe('office.column.description');
        expect(component.gridOptions.columns[1].field).toBe('organisation');
    });

    it('should clear search text', () => {
        component.ngOnInit();
        component.searchText = 'abc';
        component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
        component.clear();
        expect(component.searchText).toBe('');
        expect(component.gridOptions._search).toHaveBeenCalled();
    });

    describe('AddEditOffice', () => {
        beforeEach(() => {
            component.ngOnInit();
            modalService.openModal.mockReturnValue({
                content: {
                    onClose$: new BehaviorSubject(true),
                    addedRecordId$: new BehaviorSubject(0)
                }
            });
            component._resultsGrid.getRowSelectionParams().rowSelection = [1];
        });
        it('should handle row add correctly', () => {
            component.onRowAddedOrEdited(null, 'Add');
            expect(modalService.openModal).toHaveBeenCalledWith(OfficeMaintenanceComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-lg',
                    initialState: {
                        state: 'Add',
                        entryId: null
                    }
                });
        });

        it('should handle row edit correctly', () => {
            component.editOffice(component._resultsGrid);
            expect(modalService.openModal).toHaveBeenCalledWith(OfficeMaintenanceComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-lg',
                    initialState: {
                        state: 'Edit',
                        entryId: 1
                    }
                });
        });
    });

    describe('deleteOffices', () => {
        beforeEach(() => {
            component.ngOnInit();
            component._resultsGrid.clearSelection = jest.fn();
            component._resultsGrid.getRowSelectionParams().allSelectedItems = [{ key: 1 }, { key: 2 }];
            component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
            ipxNotificationService.openDeleteConfirmModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true), cancelled$: of(true) } });
        });

        it('should return success notification when bulk delete success for all selected records', (done) => {
            component.deleteOfficeConfirmation(component._resultsGrid);
            expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalledWith('modal.confirmDelete.message', null);
            ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null).content.confirmed$.subscribe(() => {
                expect(service.deleteOffices).toHaveBeenCalledWith([1, 2]);
                service.deleteOffices([1, 2]).subscribe(() => {
                    expect(notificationService.success).toHaveBeenCalled();
                    expect(component._resultsGrid.clearSelection).toHaveBeenCalled();
                    expect(component.gridOptions._search).toHaveBeenCalled();
                });
                done();
            });
        });

        it('should return partial complete notification when all records are not deleted', (done) => {
            const response = { hasError: true, inUseIds: [2] };
            service.deleteOffices = jest.fn().mockReturnValue(of(response));
            component.deleteOffice([1, 2]);
            expect(service.deleteOffices).toHaveBeenCalledWith([1, 2]);

            service.deleteOffices([1, 2]).subscribe(() => {
                const expected = {
                    title: 'modal.partialComplete',
                    message: 'modal.alert.partialComplete<br/>modal.alert.alreadyInUse'
                };
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
                expect(component._resultsGrid.clearSelection).toHaveBeenCalled();
                expect(component.gridOptions._search).toHaveBeenCalled();
                done();
            });
        });

        it('should return unable to complete notification when no records are deleted', (done) => {
            const response = { hasError: true, inUseIds: [1, 2] };
            service.deleteOffices = jest.fn().mockReturnValue(of(response));
            component.deleteOffice([1, 2]);
            expect(service.deleteOffices).toHaveBeenCalledWith([1, 2]);

            service.deleteOffices([1, 2]).subscribe(() => {
                const expected = {
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.alreadyInUse'
                };
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
                expect(component._resultsGrid.clearSelection).toHaveBeenCalled();
                expect(component.gridOptions._search).toHaveBeenCalled();
                done();
            });
        });
    });
});