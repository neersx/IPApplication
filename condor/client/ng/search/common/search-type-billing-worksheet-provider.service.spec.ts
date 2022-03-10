import { HttpClientMock } from 'mocks';
import { SearchTypeBillingWorksheetProviderService } from './search-type-billing-worksheet-provider.service';

describe('SearchTypeBillingWorksheetProviderService', () => {

  let service: SearchTypeBillingWorksheetProviderService;
  const httpMock = new HttpClientMock();

  beforeEach(() => {
    service = new SearchTypeBillingWorksheetProviderService(httpMock as any);
  });

  it('should load task serach type menu service', () => {
    expect(service).toBeTruthy();
  });

  it('validate getReportProviderInfo', () => {
    service.getReportProviderInfo();
    expect(httpMock.get).toHaveBeenCalledWith('api/reports/provider');
  });
});