import { ModalServiceMock } from 'mocks/modal-service.mock';
import { NotificationServiceMock } from 'mocks/notification-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { RecordalTypeComponent } from './recordal-type.component';

describe('Inprotech.Configuration.RecordalTypes', () => {
    let component: () => RecordalTypeComponent;
    const recordalTypeServiceMock = {
        deleteRecordalType: jest.fn().mockReturnValue(of({}))
    };
    let notificationService: NotificationServiceMock;
    let modalService: ModalServiceMock;

    beforeEach(() => {
        notificationService = new NotificationServiceMock();
        modalService = new ModalServiceMock();
        component = () => {
            const c = new RecordalTypeComponent(recordalTypeServiceMock as any, modalService as any, notificationService as any);
            c.viewData = {
                canAdd: true,
                canEdit: true,
                canDelete: true
            };
            c.grid = new IpxKendoGridComponentMock();
            c.ngOnInit();

            return c;
        };
    });

    it('should initialise', () => {
        const c = component();
        spyOn(c, 'buildGridOptions');

        expect(c.gridOptions).toBeDefined();
        expect(c.gridOptions.columns.length).toBe(5);
        expect(c.gridOptions.columns[0].title).toBe('recordalType.column.recordalType');
        expect(c.gridOptions.columns[0].field).toBe('recordalType');
    });
    it('should show delete confirmation', () => {
        const c = component();
        const data = { id: 1 };
        c.onRowDeleted(data as any);
        expect(notificationService.confirmDelete).toHaveBeenCalledWith({
            message: 'picklistmodal.confirm.delete'
        });
    });
    it('should show call service delete', (done) => {
        recordalTypeServiceMock.deleteRecordalType = jest.fn().mockReturnValue(of({ result: 'success' }));
        const c = component();
        c.gridOptions._search = jest.fn();
        c.deleteRecordalType(1);
        expect(recordalTypeServiceMock.deleteRecordalType).toBeCalledWith(1);
        recordalTypeServiceMock.deleteRecordalType(1).subscribe(() => {
            expect(notificationService.success).toBeCalled();
            expect(c.gridOptions._search).toBeCalled();
            done();
        });
    });
    it('should show call service delete inUse', (done) => {
        recordalTypeServiceMock.deleteRecordalType = jest.fn().mockReturnValue(of({ result: 'inUse' }));
        const c = component();
        c.deleteRecordalType(1);
        expect(recordalTypeServiceMock.deleteRecordalType).toBeCalledWith(1);
        recordalTypeServiceMock.deleteRecordalType(1).subscribe(() => {
            expect(notificationService.alert).toBeCalledWith({ message: 'recordalType.inUse', continue: 'Ok' });
            done();
        });
    });

    it('should open modal on onRowAddedOrEdited', () => {

        const c = component();
        modalService.openModal.mockReturnValue({
            content: {
                addedRecordId$: new BehaviorSubject(true),
                onClose$: new BehaviorSubject(true)
            }
        });
        c.grid.wrapper.data = {
            data: [{
                id: 1,
                status: 'A'
            }]
        };
        const data = { dataItem: { id: 1, status: 'A' } };
        c.onRowAddedOrEdited(data, 'Add');
        expect(modalService.openModal).toHaveBeenCalled();

    });
    describe('Filter search', () => {
        it('should call search grid on search click', () => {
            const c = component();
            c.gridOptions._search = jest.fn();
            c.search();
            expect(c.gridOptions._search).toBeCalled();
        });

        it('should clear default values of filter', () => {
            const c = component();
            c.gridOptions._search = jest.fn();
            c.searchText = 'ABC';
            c.clear();
            expect(c.searchText).toBe('');
            expect(c.gridOptions._search).toBeCalled();
        });
    });
});