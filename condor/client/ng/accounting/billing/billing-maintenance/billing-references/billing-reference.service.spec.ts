import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { BillingReferenceService } from './billing-reference.service';

describe('BillingReferenceService', () => {
  let service: BillingReferenceService;
  let http: HttpClientMock;

  beforeEach(() => {
    http = new HttpClientMock();
    service = new BillingReferenceService(http as any);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('call api to get cases and casesList', () => {
    http.get = jest.fn().mockReturnValue(of({}));
    service.getDefaultReferences('123', 23, 89, false, null);
    const params = {
      caseIds: '123',
      languageId: JSON.stringify(23),
      useRenewalDebtor: JSON.stringify(false),
      debtorId: JSON.stringify(89)
    };
    expect(http.get).toHaveBeenCalledWith('api/accounting/billing/bill-presentation/references', {
      params
    });
  });
});
