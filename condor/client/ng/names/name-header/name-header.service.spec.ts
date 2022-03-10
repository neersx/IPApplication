import { HttpClientMock } from 'mocks/http.mock';
import { of } from 'rxjs';
import { NameHeaderService } from './name-header.service';

describe('Service: NameHeader', () => {
  let service: NameHeaderService;
  let http: HttpClientMock;
  beforeEach(() => {
    http = new HttpClientMock();
    http.get.mockReturnValue(of(null));
    service = new NameHeaderService(http as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('getHeader', () => {
    it('should call the correct api', () => {
      service.getHeader(100);
      expect(http.get).toHaveBeenCalledWith('api/name/100/header');
    });
  });
});
