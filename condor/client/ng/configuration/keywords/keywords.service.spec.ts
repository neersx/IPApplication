import { GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { KeywordItems } from './keywords.model';
import { KeywordsService } from './keywords.service';

describe('KeywordsService', () => {
  let service: KeywordsService;
  let httpMock: HttpClientMock;
  let navService: GridNavigationServiceMock;

  beforeEach(() => {
    navService = new GridNavigationServiceMock();
    httpMock = new HttpClientMock();
    httpMock.get.mockReturnValue({
      pipe: (args: any) => {
        return [];
      }
    });
    httpMock.put.mockReturnValue(of({}));
    service = new KeywordsService(httpMock as any, navService as any);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should call the viewdata api correctly ', () => {
    service.getViewData();
    expect(httpMock.get).toHaveBeenCalledWith('api/configuration/keywords/viewdata');
  });

  it('should call the getKeywordsList api correctly ', () => {
    const criteria = {};
    jest.spyOn(navService, 'init');
    service.getKeywordsList(criteria, null);
    expect(navService.setNavigationData).toHaveBeenCalled();
    expect(httpMock.get).toHaveBeenCalledWith('api/configuration/keywords', { params: { params: 'null', q: JSON.stringify(criteria) } });
  });

  describe('Delete Keywords', () => {
    it('calls the correct API passing the parameters', () => {
      const ids = { ids: [1] };
      service.deleteKeywords([1]);
      expect(httpMock.request).toHaveBeenCalled();
      expect(httpMock.request.mock.calls[0][0]).toBe('delete');
      expect(httpMock.request.mock.calls[0][1]).toBe('api/configuration/keywords/delete');
      expect(httpMock.request.mock.calls[0][2]).toEqual({ body: ids });
    });
  });

  describe('Saving Keywords', () => {
    it('calls the correct API passing the parameters', () => {
      const entry: KeywordItems = {
        keywordNo: 1,
        keyword: 'abc',
        stopCaseKeyWord: false,
        stopNameKeyword: false
      };
      service.submitKeyWord(entry);
      expect(httpMock.put).toHaveBeenCalledWith('api/configuration/keywords/1', entry);
    });
    it('calls the correct API passing the parameters', () => {
      const entry: KeywordItems = {
        keywordNo: null,
        keyword: 'xyz',
        stopCaseKeyWord: true,
        stopNameKeyword: false
      };
      service.submitKeyWord(entry);
      expect(httpMock.post).toHaveBeenCalledWith('api/configuration/keywords', entry);
    });
  });
});
