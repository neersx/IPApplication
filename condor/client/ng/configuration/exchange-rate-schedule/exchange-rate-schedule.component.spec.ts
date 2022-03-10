import { LocalSettingsMock } from 'core/local-settings.mock';
import { IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { ExchangeRateScheduleComponent } from './exchange-rate-schedule.component';
import { ExchangeRateScheduleServiceMock } from './exchange-rate-schedule.service.mock';
import { MaintainExchangeRateScheduleComponent } from './maintain-exchange-rate-schedule/maintain-exchange-rate-schedule.component';

describe('Inprotech.Configuration.ExchangeRateSchedule', () => {
    let component: ExchangeRateScheduleComponent;
    let service: ExchangeRateScheduleServiceMock;
    let localSettings: LocalSettingsMock;
    let notificationService: NotificationServiceMock;
    let modalService: ModalServiceMock;
    let translateService: TranslateServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;

    beforeEach(() => {
        localSettings = new LocalSettingsMock();
        service = new ExchangeRateScheduleServiceMock();
        notificationService = new NotificationServiceMock();
        modalService = new ModalServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        translateService = new TranslateServiceMock();
        component = new ExchangeRateScheduleComponent(service as any, localSettings as any, modalService as any, notificationService as any, translateService as any, ipxNotificationService as any);
        component.viewData = {
            canDelete: true,
            canAdd: true,
            canEdit: true
        };
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
        component._resultsGrid.wrapper = {
            data: [
                { code: '001', description: 'Exchange Rate 1' },
                { code: '002', description: 'Exchange Rate 2' }
            ]
        } as any;
    });

    it('should initialise', () => {
        component.ngOnInit();
        spyOn(component, 'buildGridOptions');

        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.columns.length).toBe(2);
        expect(component.gridOptions.columns[0].title).toBe('exchangeRateSchedule.column.code');
        expect(component.gridOptions.columns[1].field).toBe('description');
    });

    it('should clear search text', () => {
        component.ngOnInit();
        component.searchText = 'E1';
        component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
        component.clear();
        expect(component.searchText).toBe('');
        expect(component.gridOptions._search).toHaveBeenCalled();
    });

    describe('AddEditExchangeRateSchedule', () => {
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

        it('should open modal on onRowAddedOrEdited', () => {
            modalService.openModal.mockReturnValue({
                content: {
                    addedRecordId$: new BehaviorSubject(0),
                    onClose$: new BehaviorSubject(true)
                }
            });
            component._resultsGrid.wrapper.data = {
                data: [{
                    id: 1,
                    status: 'A'
                }]
            };
            const data = { dataItem: { id: 1, status: 'A' } };
            component.onRowAddedOrEdited(data, 'A');
            expect(modalService.openModal).toHaveBeenCalled();
        });

        it('should handle row add correctly', () => {
            component.onRowAddedOrEdited(undefined, 'A');
            expect(modalService.openModal).toHaveBeenCalledWith(MaintainExchangeRateScheduleComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-lg',
                    initialState: {
                        id: undefined,
                        isAdding: true
                    }
                });
        });

        it('should handle row edit correctly', () => {
            component.onRowAddedOrEdited(1, 'E');
            expect(modalService.openModal).toHaveBeenCalledWith(MaintainExchangeRateScheduleComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-lg',
                    initialState: {
                        isAdding: false,
                        id: 1
                    }
                });
        });
    });

    describe('delete Exchange Rate Schedules', () => {
        beforeEach(() => {
            component.ngOnInit();
            component._resultsGrid.getRowSelectionParams().allSelectedItems = [{ id: '1' }, { id: '2' }];
            component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
            ipxNotificationService.openDeleteConfirmModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true), cancelled$: of(true) } });
        });

        it('should return success notification when bulk delete success for all selected records', (done) => {
            component.deleteConfirmation(component._resultsGrid);
            expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalledWith('modal.confirmDelete.message', null);
            ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null).content.confirmed$.subscribe(() => {
                expect(service.deleteExchangeRateSchedules).toHaveBeenCalledWith(['1', '2']);
                service.deleteExchangeRateSchedules(['1', '2']).subscribe(() => {
                    expect(notificationService.success).toHaveBeenCalled();
                    expect(component.gridOptions._search).toHaveBeenCalled();
                });
                done();
            });
        });

        it('should return partial complete notification when all records are not deleted', (done) => {
            const response = { hasError: true, inUseIds: [2] };
            service.deleteExchangeRateSchedules = jest.fn().mockReturnValue(of(response));
            component.delete(['1', '2']);
            expect(service.deleteExchangeRateSchedules).toHaveBeenCalledWith(['1', '2']);

            service.deleteExchangeRateSchedules(['1', '2']).subscribe(() => {
                const expected = {
                    title: 'modal.partialComplete',
                    message: 'modal.alert.partialComplete<br/>modal.alert.alreadyInUse'
                };
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
                expect(component.gridOptions._search).toHaveBeenCalled();
                done();
            });
        });

        it('should return unable to complete notification when no records are deleted', (done) => {
            const response = { hasError: true, inUseIds: [1, 2] };
            service.deleteExchangeRateSchedules = jest.fn().mockReturnValue(of(response));
            component.delete(['1', '2']);
            expect(service.deleteExchangeRateSchedules).toHaveBeenCalledWith(['1', '2']);

            service.deleteExchangeRateSchedules(['1', '2']).subscribe(() => {
                const expected = {
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.alreadyInUse'
                };
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
                expect(component.gridOptions._search).toHaveBeenCalled();
                done();
            });
        });
    });
    describe('exchange rate variation', () => {
        it('should open exchange rate variation', () => {
            component.ngOnInit();
            component._resultsGrid.getRowSelectionParams().rowSelection = ['11'];
            component._resultsGrid.getRowSelectionParams().allSelectedItems = [{ id: '11', description: 'Exchange Rate Schedule' }];
            component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
            window.open = jest.fn();
            component.openExchangeRateVariation(component._resultsGrid);
            expect(localSettings.keys.exchangeRateVariation.data.setSession).toBeCalledWith({ exchangeRateSchedule: '11', exchangeRateScheduleDesc: 'Exchange Rate Schedule' });
            expect(window.open).toHaveBeenCalledWith('#/configuration/exchange-rate-variation', '_blank');
        });
    });
});