import { HttpClientMock } from 'mocks';
import { GenerateDocumentService } from './generate-document.service';

describe('GenerateDocumentService', () => {

    let service: GenerateDocumentService;
    let httpMock: HttpClientMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        service = new GenerateDocumentService(httpMock as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });

    it('should call getDataForAdhocDoc correctly', () => {
        service.getDataForAdhocDoc$('CaseView', 1, 11, true);

        expect(httpMock.get).toHaveBeenCalledWith('api/attachment/case/1/document/11/data', { params: { addAsAttachment: 'true' } });
    });
    it('should call getGeneratedPdfDocument correctly', () => {
        service.getGeneratedPdfDocument$('CaseView', 1, 'abcd');

        expect(httpMock.get).toHaveBeenCalledWith('api/attachment/case/1/document/get-pdf?fileKey=abcd', { responseType: 'blob' });
    });

    it('should call generateAndSavePdf correctly', () => {
        service.generateAndSavePdf$('CaseView', 1, 11, 'name', 'template.dto', 'c:location', 'attach.pdf', 'abcd');

        expect(httpMock.post).toHaveBeenCalledWith('api/attachment/case/1/document/generate-pdf',
            {
                DocumentId: 11,
                DocumentName: 'name',
                Template: 'template.dto',
                SaveFileLocation: 'c:location',
                SaveFileName: 'attach.pdf',
                EntryPoint: 'abcd'
            }
        );
    });
});