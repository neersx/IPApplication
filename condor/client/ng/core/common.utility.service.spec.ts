import { Observable } from 'rxjs';
import { ReportExportFormat } from 'search/results/report-export.format';
import { CommonUtilityService } from './common.utility.service';
import { WindowRefMock } from './window-ref.mock';

describe('CommonUtilityService', () => {
  let service: CommonUtilityService;
  let windowRefMock: WindowRefMock;
  let httpClientMock;

  beforeEach(() => {
    windowRefMock = new WindowRefMock({
      location: {
        origin: 'http://localhost',
        pathname: '/cpainproma/apps/'
      }
    });
    httpClientMock = { post: jest.fn().mockReturnValue(new Observable()) };
    service = new CommonUtilityService(windowRefMock, httpClientMock);
  });

  it('should create', () => {
    expect(service).toBeTruthy();
  });

  it('validate formatString', () => {

    const result = service.formatString('{0}, {1} and {2}', 'case1', 'case2', 'case3');
    expect(result).toEqual('case1, case2 and case3');
  });

  it('validate getTimeOnlyFormat', () => {
    const result = service.getTimeOnlyFormat();
    expect(result).toEqual('hh:mm:ss a');
  });

  it('validate getBasePath', () => {
    const result = service.getBasePath();
    expect(result).toEqual('http://localhost/cpainproma/apps/');
  });

  it('Validate export', () => {
    const request = { processId: 12, exportFormat: ReportExportFormat.PDF };
    const exportUrl = 'api/search/case/sanitycheck/export';
    service.export(exportUrl, request);
    expect(httpClientMock.post).toHaveBeenCalledWith(exportUrl, request, { observe: 'response', responseType: 'arraybuffer' });
  });

});