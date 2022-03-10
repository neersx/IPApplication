import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { PingService } from './ping.service';

describe('Service: Ping', () => {
  let http: HttpClientMock;
  let service: PingService;
  beforeEach(() => {
    http = new HttpClientMock();
    http.put.mockReturnValue(of({}));
    service = new PingService(http as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('ping', () => {
    it('should call correct api', () => {
      service.ping();

      expect(http.put).toHaveBeenCalledWith('api/signin/ping', {});
    });
  });
});
