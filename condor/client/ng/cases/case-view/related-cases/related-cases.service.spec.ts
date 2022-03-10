import { HttpClientMock } from 'mocks';
import { RelatedCasesService } from './related-cases.service';

describe('Service: RelatedCases', () => {
  let http: HttpClientMock;
  let service: RelatedCasesService;
  beforeEach(() => {
    http = new HttpClientMock();
    service = new RelatedCasesService(http as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });
  describe('getRelatedCases', () => {
    it('should call get for the related cases API', () => {
      const params = { skip: 0, take: 10 };
      service.getRelatedCases(1, params);

      expect(http.get).toHaveBeenCalledWith(`api/case/${1}/relatedcases`, { params: { params: JSON.stringify(params) } });
    });
  });
});
