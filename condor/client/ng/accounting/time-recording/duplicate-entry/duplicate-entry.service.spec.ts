import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { DuplicateEntryService } from './duplicate-entry.service';

describe('Service: DuplicateEntry', () => {
  let http: HttpClientMock;
  let service: DuplicateEntryService;

  beforeEach(() => {
    http = new HttpClientMock();
    service = new DuplicateEntryService(http as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  it('initiate request does a http post to create duplicate entries', () => {
    const param = { param: 'someparam' };
    http.post = jest.fn().mockReturnValue(of(10));
    service.requestDuplicateOb$.subscribe();

    service.initiateDuplicationRequest(param);

    expect(http.post).toHaveBeenCalledWith('api/accounting/time/copy', param);
  });
});
