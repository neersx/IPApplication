import { IpxGridOptionsMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { TaxCodeMock } from 'mocks/tax-code.mock';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { TaxCodeComponent } from './tax-code-component';
describe('TaxCodeComponent', () => {
    let component: TaxCodeComponent;
    const service = new TaxCodeMock();
    const stateService = new StateServiceMock();
    const modalService = new ModalServiceMock();
    const notificationService = new NotificationServiceMock();
    const gridoptionsMock = new IpxGridOptionsMock();
    const translateService = { instant: jest.fn() };
    beforeEach(() => {
        component = new TaxCodeComponent(service as any, translateService as any,
            modalService as any, notificationService as any, stateService as any);
        component.gridOptions = new IpxGridOptionsMock() as any;
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
        component.taxCodeGrid = new IpxKendoGridComponentMock() as any;
    });
    it('should initialize TaxCodeComponent', () => {
        expect(component).toBeTruthy();
    });
    it('should call OnInit', () => {
        component.ngOnInit();
    });
    it('should call openModal method', () => {
        const state = 'adding';
        component.openModal(null, state);
        expect(modalService.openModal).toBeCalled();
    });
    it('should call dataItemByTaxCode method', () => {
        const taxRateId = 1;
        component._resultsGrid = { wrapper: { data: [{ id: 1 }, { id: 2 }] } };
        const result = component.dataItemByTaxCode(taxRateId);
        expect(result).toEqual({ id: 1 });
    });
    it('should call deleteSelectedTaxCodes method', () => {
        component.deleteSelectedTaxCodes();
        expect(service.deleteTaxCodes).toBeCalled();
    });
    it('should call search method', () => {
        const request = { value: '1' };
        component.gridOptions = gridoptionsMock;
        spyOn(gridoptionsMock, '_search').and.returnValue([]);
        component.search(request);
        expect(component.gridOptions._search).toBeCalled();
        expect(component.searchCriteria.text).toEqual('1');
    });
    it('should call search method', () => {
        component.gridOptions = gridoptionsMock;
        spyOn(gridoptionsMock, '_search').and.returnValue([]);
        component.clear();
        expect(component.gridOptions._search).toBeCalled();
        expect(component.searchCriteria.text).toEqual('');
    });
});