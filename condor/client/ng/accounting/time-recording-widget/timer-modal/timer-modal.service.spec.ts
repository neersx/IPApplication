import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { TimerModalService } from './timer-modal.service';
describe('Service: TimerModal', () => {
  let http: HttpClientMock;
  let service: TimerModalService;

  beforeEach(() => {
    http = new HttpClientMock();
    service = new TimerModalService(http as any);
  });
  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  it('getDefaultNarrativeFromActivity calls the server api correctly', done => {
    http.get = jest.fn().mockReturnValue(of({}));

    service.getDefaultNarrativeFromActivity('act1', 10, null, 12)
      .subscribe(() => {
        expect(http.get).toHaveBeenCalled();
        expect(http.get.mock.calls[0][0]).toEqual('api/accounting/time/narrative');
        expect(http.get.mock.calls[0][1].params.activityKey).toEqual('act1');
        expect(http.get.mock.calls[0][1].params.caseKey).toEqual('10');
        expect(http.get.mock.calls[0][1].params.debtorKey).toBeNull();
        expect(http.get.mock.calls[0][1].params.staffNameId).toEqual('12');

        done();
      });
  });
});
