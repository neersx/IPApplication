import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { SplitWipService } from './split-wip.service';

describe('SplitWipService', () => {
  let http: HttpClientMock;
  let service: SplitWipService;

  beforeEach(() => {
    http = new HttpClientMock();
    service = new SplitWipService(http as any);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('Split Wip Services', () => {
    it('calls api to get wip base data and permissions', () => {
      http.get = jest.fn().mockReturnValue(of({}));
      service.getWipSupportData$();
      expect(http.get).toHaveBeenCalledWith('api/accounting/wip-adjustments/view-support');
    });

    it('call api to get split wip details', () => {
      http.get = jest.fn().mockReturnValue(of({}));
      service.getItemForSplitWip$(123, 1, 1);
      expect(http.get).toHaveBeenCalledWith('api/accounting/wip-adjustments/split-item', {
        params: {
          entityKey: '123',
          transKey: '1',
          wipSeqKey: '1'
        }
      });
    });
  });
});
