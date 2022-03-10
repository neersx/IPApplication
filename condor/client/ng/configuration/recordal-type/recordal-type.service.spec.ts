import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { RecordalTypeService } from './recordal-type.service';

describe('RecordalTypeService', () => {

    let service: RecordalTypeService;
    let httpMock: HttpClientMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        httpMock.get.mockReturnValue(of({}));
        httpMock.put.mockReturnValue(of({}));
        service = new RecordalTypeService(httpMock as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('getRecordalType', () => {
        it('should call the api correctly ', () => {
            const criteria = {};
            service.getRecordalType(criteria, null);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/recordaltypes', { params: { params: 'null', q: JSON.stringify(criteria) } });
        });
        it('should call the viewdata api correctly ', () => {
            service.getViewData();
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/recordaltypes/viewdata');
        });

        it('should call the getRecordalTypeFormData api correctly ', () => {
            service.getRecordalTypeFormData(123);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/recordaltypes/123');
        });

        it('should call the getRecordalTypeFormData api correctly ', () => {
            service.getRecordalElementFormData(123);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/recordaltypes/element/123');
        });

        it('should call getAllElements api correctly ', () => {
            service.getAllElements();
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/recordaltypes/elements/');
        });

        it('should call submit recordal type api correctly ', () => {
            const request: any = {};
            service.submitRecordalType(request);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/recordaltypes/submit/', request);
        });
    });
    describe('Deleting recordal type', () => {
        it('calls the correct API passing the parameters', () => {
            const entry1 = 1;
            service.deleteRecordalType(entry1);
            expect(httpMock.request).toHaveBeenCalled();
            expect(httpMock.request.mock.calls[0][0]).toBe('delete');
            expect(httpMock.request.mock.calls[0][1]).toBe('api/configuration/recordaltypes/delete/1');
        });
    });
});