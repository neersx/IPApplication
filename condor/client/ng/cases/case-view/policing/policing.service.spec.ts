import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { PolicingService } from './policing.service';

describe('Service: Policing', () => {
  let service: PolicingService;
  let http: HttpClientMock;
  beforeEach(() => {
    http = new HttpClientMock();
    service = new PolicingService(http as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('policeAction', () => {
    it('should call the appropriate API', () => {
      const request = {
        actionId: '',
        caseId: 1,
        isPoliceImmediately: true
      } as any;
      http.post.mockReturnValue(of(null));
      service.policeAction(request);

      expect(http.post).toHaveBeenCalledWith('api/cases/policeAction', request);
    });
  });

  describe('policeBatch', () => {
    it('should call the appropriate API', () => {
      http.post.mockReturnValue(of(null));
      service.policeBatch(1);

      expect(http.post).toHaveBeenCalledWith('api/cases/policeBatch', { batchNo: 1 });
    });
  });
});
