import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { ReportExportFormat } from './report-export.format';
import { SearchExportService } from './search-export.service';
describe('AttributesComponent', () => {
    let service: SearchExportService;
    const httpMock = new HttpClientMock();
    let exportFormat: ReportExportFormat;
    beforeEach(() => {
        SearchTypeConfigProvider.savedConfig = { baseApiRoute: 'api/search/case/' } as any;
        service = new SearchExportService(httpMock as any);
    });
    it('should create the service', async(() => {
        expect(service).toBeTruthy();
    }));

    it('should call the exportGlobalCaseChangeResultToExcel method', async(() => {

        const presentationType = 'presentationType';
        const searchName = 'global field update';
        const globalProcessKey = 1;
        exportFormat = ReportExportFormat.Excel;
        const params = { skip: null, take: null };
        spyOn(httpMock, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
        service.exportGlobalChangeResultToExcel(globalProcessKey, presentationType, params, searchName, exportFormat);
        expect(httpMock.post).toHaveBeenCalled();
    }));
    it('should call the exportToExcel method', () => {
        const filter = [{ caseKeys: { operator: 0, value: '-486,-470' } }];
        const searchName = 'US Trademark';
        const queryKey = '36';
        const queryContextKey = 2;
        const forceConstructXmlCriteria = true;
        exportFormat = ReportExportFormat.Excel;
        const params = { skip: null, take: null };
        spyOn(httpMock, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
        service.export(filter, params, searchName, queryKey, queryContextKey, forceConstructXmlCriteria, null, exportFormat, 1);
        expect(httpMock.post).toHaveBeenCalled();
    });
    it('should call the exportToCpaXml method', () => {
        const filter = [{ caseKeys: { operator: 0, value: '-486,-470' } }];
        spyOn(httpMock, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });

        service.exportToCpaXml(filter, 2);
        expect(httpMock.post).toHaveBeenCalled();
    });
    it('should call the generate content id method', () => {
        service.generateContentId('eeauf');

        expect(httpMock.get).toHaveBeenCalledWith('api/export/content/eeauf');
    });
    it('should call the remove all contents method', () => {
        service.removeAllContents('eeauf');

        expect(httpMock.post).toHaveBeenCalledWith('api/export/content/remove/eeauf', null);
    });
});
