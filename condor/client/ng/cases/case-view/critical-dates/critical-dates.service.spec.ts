import { HttpClientMock } from 'mocks';
import { CriticalDatesService } from './critical-dates.service';

describe('Service: RelatedCases', () => {
  let http: HttpClientMock;
  let service: CriticalDatesService;
  beforeEach(() => {
    http = new HttpClientMock();
    service = new CriticalDatesService(http as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });
  describe('getDates', () => {
    it('should call get for the related cases API', () => {
      const testParams = { test: 'test' };
      service.getDates(1, testParams);

      expect(http.get).toHaveBeenCalledWith(`api/case/${1}/critical-dates`, expect.objectContaining({ params: expect.objectContaining({ params: JSON.stringify(testParams) }) }));
    });
  });
});
