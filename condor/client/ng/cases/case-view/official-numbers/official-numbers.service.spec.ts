import { HttpClientMock } from 'mocks';
import { OfficialNumbersService } from './official-numbers.service';

describe('Service: RelatedCases', () => {
  let http: HttpClientMock;
  let service: OfficialNumbersService;
  beforeEach(() => {
    http = new HttpClientMock();
    service = new OfficialNumbersService(http as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });
  describe('getCaseViewIpOfficeNumbers', () => {
    it('should call get for the right API', () => {
      const queryParams = {
        test: 'test'
      };
      service.getCaseViewIpOfficeNumbers(1, queryParams);

      expect(http.get).toHaveBeenCalledWith(`api/case/${1}/officialnumbers/ipoffice`, {
        params: {
          params: JSON.stringify(queryParams)
        }
      });
    });
  });

  describe('getCaseViewOtherNumbers', () => {
    it('should call get for the right API', () => {
      const queryParams = {
        test: 'test'
      };
      service.getCaseViewOtherNumbers(1, queryParams);

      expect(http.get).toHaveBeenCalledWith(`api/case/${1}/officialnumbers/other`, {
        params: {
          params: JSON.stringify(queryParams)
        }
      });
    });
  });
});