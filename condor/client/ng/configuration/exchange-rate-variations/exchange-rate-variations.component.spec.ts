import { criteriaPurposeCode } from 'configuration/rules/screen-designer/case/search/search.service';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { CaseValidCombinationServiceMock, ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks/notification-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { ExchangeRateVariationComponent } from './exchange-rate-variations.component';
import { ExchangeRateVariationFormData } from './exchange-rate-variations.model';
import { ExchangeRateVariationServiceMock } from './exchange-rate-variations.service.mock';
import { MaintainExchangerateVarComponent } from './maintain-exchangerate-var/maintain-exchangerate-var.component';

describe('Inprotech.Configuration.exchangeRateVariations', () => {
    let component: ExchangeRateVariationComponent;
    let localSettings: LocalSettingsMock;
    let cvs: CaseValidCombinationServiceMock;
    let searchService: any;
    let service: ExchangeRateVariationServiceMock;
    let cdRef: ChangeDetectorRefMock;
    let notificationService: NotificationServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let modalService: ModalServiceMock;
    let translateService: TranslateServiceMock;
    beforeEach(() => {
        service = new ExchangeRateVariationServiceMock();
        notificationService = new NotificationServiceMock();
        localSettings = new LocalSettingsMock();
        cvs = new CaseValidCombinationServiceMock();
        cdRef = new ChangeDetectorRefMock();
        modalService = new ModalServiceMock();
        searchService = {
            setSearchData: jest.fn(),
            getCaseCharacteristics$: jest.fn().mockReturnValue(of(null))
        };
        notificationService = new NotificationServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        translateService = new TranslateServiceMock();
        component = new ExchangeRateVariationComponent(service as any, localSettings as any, cvs as any, searchService, cdRef as any, ipxNotificationService as any, modalService as any, notificationService as any, translateService as any);
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
        localSettings.keys.exchangeRateVariation.data.setSession({ currency: 'AUD', currencyDesc: 'Australian Dollar' });
        component.isCaseCategoryDisabled.next = jest.fn();
        component.ngOnInit();
        spyOn(component, 'buildGridOptions');

        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.columns.length).toBe(12);
        expect(component.gridOptions.columns[0].title).toBe('exchangeRateVariation.columns.currency');
        expect(component.gridOptions.columns[1].field).toBe('exchangeRateSchedule');

        expect(component.formData.currency.id).toBe('AUD');
        expect(component.formData.currency.description).toBe('Australian Dollar');
        expect(localSettings.keys.exchangeRateVariation.data.getSession).toBe(undefined);
        expect(cvs.initFormData).toBeCalledWith(component.formData);
        expect(component.isCaseCategoryDisabled.next).toBeCalledWith(true);
    });
    it('should initialise with Exchange rate schedule', () => {
        localSettings.keys.exchangeRateVariation.data.setSession({ exchangeRateSchedule: 11, exchangeRateScheduleDesc: 'Exchange Rate Schedule' });
        component.isCaseCategoryDisabled.next = jest.fn();
        component.ngOnInit();

        expect(component.formData.exchangeRateSchedule.id).toBe(11);
        expect(component.formData.exchangeRateSchedule.description).toBe('Exchange Rate Schedule');
        expect(localSettings.keys.exchangeRateVariation.data.getSession).toBe(undefined);
    });
    it('should call grid search on search', () => {
        component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
        component.search();
        expect(component.gridOptions._search).toBeCalled();
    });
    it('should clear formdata on clear', () => {
        component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
        component.formData = new ExchangeRateVariationFormData();
        component.formData.currency = 'AUD';
        component.clear();
        expect(component.formData.currency).toBe(undefined);
        expect(component.gridOptions._search).toBeCalled();
    });
    it('should clear case when useCase checkbox is uncecked', () => {
        component.formData = new ExchangeRateVariationFormData();
        component.formData.case = { key: 1 };
        component.useCaseChanged(false);
        expect(component.formData.case).toBe(null);
    });
    describe('onCaseChange', () => {
        it('should do nothing on null call', () => {
            component.onCaseChange(null);
            expect(searchService.getCaseCharacteristics$).not.toHaveBeenCalled();
        });
        it('should do nothing on empty key', () => {
            component.onCaseChange({ key: null });
            expect(searchService.getCaseCharacteristics$).not.toHaveBeenCalled();
        });
        it('should call getCaseCharacteristics$ with the right params', () => {
            component.onCaseChange({ key: 1 });
            expect(searchService.getCaseCharacteristics$).toHaveBeenCalledWith(1, criteriaPurposeCode.ScreenDesignerCases);
        });
        it('should set the correct values on successful return from server', () => {
            const serverValue = {
                jurisdiction: 'jurisdiction',
                caseCategory: 'caseCategory',
                caseType: 'caseType',
                propertyType: 'propertyType',
                subType: 'subType'
            };
            component.ngOnInit();
            searchService.getCaseCharacteristics$.mockReturnValue(of(serverValue));
            component.onCaseChange({ key: 1 });
            expect(component.formData).toEqual(expect.objectContaining(serverValue));
        });
    });

    describe('delete Exchange Rate Variations', () => {
        beforeEach(() => {
            component.ngOnInit();
            component._resultsGrid.clearSelection = jest.fn();
            component._resultsGrid.getRowSelectionParams().allSelectedItems = [{ id: 1 }, { id: 2 }];
            component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
            ipxNotificationService.openDeleteConfirmModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true), cancelled$: of(true) } });
        });
        it('should return success notification when bulk delete success for all selected records', (done) => {
            component.deleteConfirmation(component._resultsGrid);
            expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalledWith('modal.confirmDelete.message', null);
            ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null).content.confirmed$.subscribe(() => {
                expect(service.deleteExchangeRateVariations).toHaveBeenCalledWith([1, 2]);
                service.deleteExchangeRateVariations([1, 2]).subscribe(() => {
                    expect(notificationService.success).toHaveBeenCalled();
                    expect(component._resultsGrid.clearSelection).toHaveBeenCalled();
                    expect(component.gridOptions._search).toHaveBeenCalled();
                });
                done();
            });
        });
        it('should return partial complete notification when all records are not deleted', (done) => {
            const response = { hasError: true, inUseIds: [2] };
            service.deleteExchangeRateVariations = jest.fn().mockReturnValue(of(response));
            component.delete([1, 2]);
            expect(service.deleteExchangeRateVariations).toHaveBeenCalledWith([1, 2]);

            service.deleteExchangeRateVariations([1, 2]).subscribe(() => {
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
            service.deleteExchangeRateVariations = jest.fn().mockReturnValue(of(response));
            component.delete([1, 2]);
            expect(service.deleteExchangeRateVariations).toHaveBeenCalledWith([1, 2]);

            service.deleteExchangeRateVariations([1, 2]).subscribe(() => {
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
    describe('AddEditExchangeRateVariation', () => {
        beforeEach(() => {
            component.ngOnInit();
            modalService.openModal.mockReturnValue({
                content: {
                    onClose$: new BehaviorSubject(true),
                    addedRecordId$: new BehaviorSubject(0)
                }
            });
        });
        it('should handle row add correctly', () => {
            component.formData = new ExchangeRateVariationFormData();
            component.formData.currency = 'AUD';
            component.onRowAddedOrEdited(undefined, 'A');
            expect(modalService.openModal).toHaveBeenCalledWith(MaintainExchangerateVarComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-xl',
                    initialState: {
                        isAdding: true,
                        id: undefined,
                        currencyCodeValue: component.formData.currency,
                        exchangeRateScheduleCodeValue: component.formData.exchangeRateSchedule
                    }
                });
        });

        it('should handle row edit correctly', () => {
            component.onRowAddedOrEdited(1, 'E');
            expect(modalService.openModal).toHaveBeenCalledWith(MaintainExchangerateVarComponent,
                {
                    animated: false,
                    backdrop: 'static',
                    class: 'modal-xl',
                    initialState: {
                        isAdding: false,
                        id: 1,
                        currencyCodeValue: undefined,
                        exchangeRateScheduleCodeValue: undefined
                    }
                });
        });
    });
});