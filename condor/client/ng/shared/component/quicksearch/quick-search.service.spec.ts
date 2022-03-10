import { HttpClientMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { QuickSearchService } from './quick-search.service';

describe('QuickSearchService', () => {
  let service: QuickSearchService;
  let httpClientSpy: any;
  const translateServiceMock = new TranslateServiceMock();

  beforeEach(() => {
    httpClientSpy = new HttpClientMock();
    service = new QuickSearchService(
      httpClientSpy,
      translateServiceMock as any
    );
  });
  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should pass correct parameters', () => {
    const term = 'Irn123';
    const url = 'api/quicksearch/typeahead?q=';
    httpClientSpy.get.mockReturnValue(
      of([{id: 123, irn: 'Irn123'}, {id: 456, irn: 'Irn345'}])
    );
    service.get(term);
    expect(httpClientSpy.get).toHaveBeenCalled();

    service.get(term);
    expect(httpClientSpy.get).toHaveBeenCalledWith(url + term);
  });
});
