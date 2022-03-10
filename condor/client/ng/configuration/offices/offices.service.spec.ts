import { GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { OfficeData } from './offices.model';
import { OfficeService } from './offices.service';
describe('OfficeService', () => {

    let service: OfficeService;
    let httpMock: HttpClientMock;
    let gridNavigationService: GridNavigationServiceMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        gridNavigationService = new GridNavigationServiceMock();
        httpMock.get.mockReturnValue({
            pipe: (args: any) => {
                return [];
            }
        });
        httpMock.put.mockReturnValue(of({}));
        service = new OfficeService(httpMock as any, gridNavigationService as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });
    it('should get viewData', () => {
        service.getViewData();
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/offices/viewdata');
    });
    it('should call the getOffices api correctly ', () => {
        const criteria = {};
        jest.spyOn(gridNavigationService, 'init');
        service.getOffices(criteria, null);
        expect(gridNavigationService.setNavigationData).toHaveBeenCalled();
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/offices', { params: { params: 'null', q: JSON.stringify(criteria) } });
    });
    it('should get regions', () => {
        service.getRegions();
        expect(httpMock.get).toHaveBeenCalledWith('api/picklists/tablecodes?tableType=139');
    });
    it('should get printers', () => {
        service.getPrinters();
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/offices/printers');
    });
    it('should office detail should call api correctly ', () => {
        service.getOffice(1);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/offices/1');
    });
    describe('Saving Office', () => {
        it('calls the correct API passing the parameters', () => {
            const entry: OfficeData = {
                id: 1
            };
            service.saveOffice(entry);
            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/offices/1', entry);
        });
        it('calls the correct API passing the parameters', () => {
            const entry: OfficeData = {
                id: null
            };
            service.saveOffice(entry);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/offices', entry);
        });
    });
    describe('Deleting Office', () => {
        it('calls the correct API passing the parameters', () => {
            const officeIds = { ids: [1] };
            service.deleteOffices([1]);
            expect(httpMock.request).toHaveBeenCalled();
            expect(httpMock.request.mock.calls[0][0]).toBe('delete');
            expect(httpMock.request.mock.calls[0][1]).toBe('api/configuration/offices/delete');
            expect(httpMock.request.mock.calls[0][2]).toEqual({ body: officeIds });

        });
    });
});