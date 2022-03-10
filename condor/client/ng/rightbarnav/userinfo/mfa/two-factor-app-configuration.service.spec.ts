import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { TwoFactorAppConfigurationService } from './two-factor-app-configuration.service';

describe('TwoFactorAppConfigurationService', () => {
  let httpClientSpy: HttpClientMock;
  let service: TwoFactorAppConfigurationService;
  beforeEach(() => {
    httpClientSpy = new HttpClientMock();
    service = new TwoFactorAppConfigurationService(httpClientSpy as any);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
  describe('GetTwoFactorTempKey', () => {
    it('should call the correct API', () => {
      service.GetTwoFactorTempKey();
      expect(httpClientSpy.get).toHaveBeenCalledWith('api/twoFactorAuthPreference/twoFactorTempKey');
    });
  });

  describe('VerifyAndSaveTempKey', () => {
    it('should call the correct API', () => {
      const appCode = 'testAppCode';
      httpClientSpy.post.mockReturnValue(of({ status: 'success' }));
      service.VerifyAndSaveTempKey(appCode);
      expect(httpClientSpy.post).toHaveBeenCalledWith('api/twoFactorAuthPreference/twoFactorTempKeyVerify', { appCode });
    });
  });
});