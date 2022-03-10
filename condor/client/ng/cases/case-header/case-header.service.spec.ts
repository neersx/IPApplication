import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { CaseHeaderService } from './case-header.service';

describe('Service: CaseHeader', () => {
  let service: CaseHeaderService;
  let http: HttpClientMock;
  beforeEach(() => {
    http = new HttpClientMock();
    service = new CaseHeaderService(http as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('getHeader', () => {
    it('should call the api with the correct parameters', () => {
      http.get.mockReturnValue(of(null));
      service.getHeader(123);

      expect(http.get).toHaveBeenCalledWith('api/case/123/header');
    });
  });
});
