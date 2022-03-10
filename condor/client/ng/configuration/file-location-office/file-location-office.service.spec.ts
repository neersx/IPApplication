import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { FileLocationOfficeService } from './file-location-office.service';
describe('OfficeService', () => {

    let service: FileLocationOfficeService;
    let httpMock: HttpClientMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        httpMock.get.mockReturnValue({
            pipe: (args: any) => {
                return [];
            }
        });
        httpMock.put.mockReturnValue(of({}));
        service = new FileLocationOfficeService(httpMock as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });
    it('should call the getFileLocationOffices api correctly ', () => {
        service.getFileLocationOffices(null);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/file-location-office', { params: { params: 'null' } });
    });
    it('calls the saveFileLocationOffice API passing the parameters', () => {
        const entries = [{ id: 1 }, { id: 2 }];
        service.saveFileLocationOffice(entries);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/file-location-office', { rows: entries });
    });
});