
import { Observable } from 'rxjs';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { ReportExportFormat } from 'search/results/report-export.format';
import { SanityCheckResultsService } from './sanity-check-results.service';

describe('SanityCheckResultsService', () => {
  let service: SanityCheckResultsService;
  let httpClientSpy;
  beforeEach(() => {
    httpClientSpy = { get: jest.fn(), post: jest.fn().mockReturnValue(new Observable()) };
    service = new SanityCheckResultsService(httpClientSpy);
    SearchTypeConfigProvider.savedConfig = { baseApiRoute: 'api/search/case/sanitycheck/' } as any;
  });

  it('should be created', () => {
    expect(service).toBeDefined();
  });

  it('Validate to get sanity check results', () => {
    const request = { processId: 12, params: { skip: 0, take: 10, filters: null } };
    service.getSanityCheckResults(request.processId, request.params);
    expect(httpClientSpy.post).toHaveBeenCalledWith('api/search/case/sanitycheck/results', request);
  });
});