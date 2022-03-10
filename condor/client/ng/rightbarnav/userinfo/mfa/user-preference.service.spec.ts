import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { UserPreferenceService } from './user-preference.service';

describe('UserPreferenceService', () => {
  let httpClientSpy: HttpClientMock;
  let fixture: UserPreferenceService;

  beforeEach(() => {
    httpClientSpy = new HttpClientMock();
    fixture = new UserPreferenceService(httpClientSpy as any);
  });

  it('should be created', () => {
    expect(fixture).toBeTruthy();
  });

  describe('GetUserTwoFactorAuthPreferences', () => {
    it('should return the expected response', () => {
      const response = {
        configuredModes: ['email'],
        preference: 'email',
        enabled: false
      };
      httpClientSpy.get.mockReturnValue(of(response));
      fixture.GetUserTwoFactorAuthPreferences().then(
        result => expect(result).toEqual(response)
      );
    });

    it('should call the expected API', () => {
      const response = {
        configuredModes: [],
        preference: '',
        enabled: false
      };
      httpClientSpy.get.mockReturnValue(of(response));
      fixture.GetUserTwoFactorAuthPreferences();

      expect(httpClientSpy.get).toHaveBeenCalledWith('api/twoFactorAuthPreference');
    });
  });

  describe('SetUserTwoFactorAuthPreferences', () => {
    it('should call the two factor preference api with the correct parameters', () => {
      const preference = { Preference: 'preference' };
      httpClientSpy.put.mockReturnValue(of(null));
      fixture.SetUserTwoFactorAuthPreferences(preference);

      expect(httpClientSpy.put).toHaveBeenCalledWith('api/twoFactorAuthPreference', preference);
    });
  });

  describe('RemoveTwoFactorAppConfiguration', () => {
    it('should call the two factor preference api with the correct parameters', () => {
      httpClientSpy.post.mockReturnValue(of(null));

      fixture.RemoveTwoFactorAppConfiguration();

      expect(httpClientSpy.post).toHaveBeenCalledWith('api/twoFactorAuthPreference/twoFactorAppKeyDelete', {});
    });
  });
});
