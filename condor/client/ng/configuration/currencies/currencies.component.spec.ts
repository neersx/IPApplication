import { LocalSettingsMock } from 'core/local-settings.mock';
import { IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { CurrenciesComponent } from './currencies.component';
import { CurrenciesServiceMock } from './currencies.service.mock';
import { ExchangeRateHistoryComponent } from './exchange-rate-history/exchange-rate-history.component';
import { MaintainCurrenciesComponent } from './maintain-currencies/maintain-currencies.component';

describe('Inprotech.Configuration.currencies', () => {
    let component: CurrenciesComponent;
    let localSettings: LocalSettingsMock;
    let notificationService: NotificationServiceMock;
    let modalService: ModalServiceMock;
    let translateService: TranslateServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let service: CurrenciesServiceMock;

    beforeEach(() => {
        service = new CurrenciesServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        translateService = new TranslateServiceMock();
        localSettings = new LocalSettingsMock();
        notificationService = new NotificationServiceMock();
        modalService = new ModalServiceMock();
        component = new CurrenciesComponent(service as any, localSettings as any, modalService as any, translateService as any, notificationService as any, ipxNotificationService as any);
        component.viewData = {
            canDelete: true,
            canAdd: true,
            canEdit: true
        };
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
        component._resultsGrid.wrapper = {
            data: [
                { code: 'AUS', description: 'Australia' },
                { code: 'USA', description: 'America' }
            ]
        } as any;
    });

    it('should initialise', () => {
        component.ngOnInit();
        spyOn(component, 'buildGridOptions');

        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.columns.length).toBe(9);
        expect(component.gridOptions.columns[1].title).toBe('currencies.column.code');
        expect(component.gridOptions.columns[2].field).toBe('currencyDescription');
    });

    it('should clear search text', () => {
        component.ngOnInit();
        component.searchText = 'AUS';
        component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
        component.clear();
        expect(component.searchText).toBe('');
        expect(component.gridOptions._search).toHaveBeenCalled();
    });
    it('should open exchange rate history', () => {
        const dataItem = { id: 'AUD' };
        component.openHistory(dataItem);
        expect(modalService.openModal).toHaveBeenCalledWith(ExchangeRateHistoryComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                currencyId: dataItem.id
            }
        });
    });

    describe('exchange rate variation', () => {
        it('should open exchange rate variation', () => {
            component.ngOnInit();
            component._resultsGrid.getRowSelectionParams().rowSelection = ['AUD'];
            component._resultsGrid.getRowSelectionParams().allSelectedItems = [{ id: 'AUD', currencyDescription: 'Australian Dollar' }];
            component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
            window.open = jest.fn();
            component.openExchangeRateVariation(component._resultsGrid);
            expect(localSettings.keys.exchangeRateVariation.data.setSession).toBeCalledWith({ currency: 'AUD', currencyDesc: 'Australian Dollar' });
            expect(window.open).toHaveBeenCalledWith('#/configuration/exchange-rate-variation', '_blank');
        });
    });

    describe('deleteCurrencies', () => {
        beforeEach(() => {
            component.ngOnInit();
            component._resultsGrid.getRowSelectionParams().allSelectedItems = [{ id: '1' }, { id: '2' }];
            component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
            ipxNotificationService.openDeleteConfirmModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true), cancelled$: of(true) } });
        });

        it('should return success notification when bulk delete success for all selected records', (done) => {
            component.deleteCurrenciesConfirmation(component._resultsGrid);
            expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalledWith('modal.confirmDelete.message', null);
            ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null).content.confirmed$.subscribe(() => {
                expect(service.deleteCurrencies).toHaveBeenCalledWith(['1', '2']);
                service.deleteCurrencies(['1', '2']).subscribe(() => {
                    expect(notificationService.success).toHaveBeenCalled();
                    expect(component.gridOptions._search).toHaveBeenCalled();
                });
                done();
            });
        });

        it('should return partial complete notification when all records are not deleted', (done) => {
            const response = { hasError: true, inUseIds: [2] };
            service.deleteCurrencies = jest.fn().mockReturnValue(of(response));
            component.deleteCurrencies(['1', '2']);
            expect(service.deleteCurrencies).toHaveBeenCalledWith(['1', '2']);

            service.deleteCurrencies(['1', '2']).subscribe(() => {
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
            service.deleteCurrencies = jest.fn().mockReturnValue(of(response));
            component.deleteCurrencies(['1', '2']);
            expect(service.deleteCurrencies).toHaveBeenCalledWith(['1', '2']);

            service.deleteCurrencies(['1', '2']).subscribe(() => {
                const expected = {
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.alreadyInUse'
                };
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
                expect(component.gridOptions._search).toHaveBeenCalled();
                done();
            });
        });

        it('should open modal on onRowAddedOrEdited', () => {
            modalService.openModal.mockReturnValue({
                content: {
                    addedRecordId$: new BehaviorSubject(true),
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
    });
    describe('AddEditCurrency', () => {
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
            component.onRowAddedOrEdited(undefined, 'A');
            expect(modalService.openModal).toHaveBeenCalledWith(MaintainCurrenciesComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-xl',
                    initialState: {
                        isAdding: true,
                        id: undefined
                    }
                });
        });

        it('should handle row edit correctly', () => {
            component.onRowAddedOrEdited(1, 'E');
            expect(modalService.openModal).toHaveBeenCalledWith(MaintainCurrenciesComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-xl',
                    initialState: {
                        isAdding: false,
                        id: 1
                    }
                });
        });
    });
});