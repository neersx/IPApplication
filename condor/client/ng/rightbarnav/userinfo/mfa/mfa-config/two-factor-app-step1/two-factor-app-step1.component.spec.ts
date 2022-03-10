import { ChangeDetectorRefMock, HttpClientMock, NotificationServiceMock } from 'mocks';
import { UserPreferenceService } from '../../user-preference.service';
import { TwoFactorAppStep1Component } from './two-factor-app-step1.component';

describe('TwoFactorAppStep1Component', () => {
  let component: TwoFactorAppStep1Component;
  beforeEach(() => {
    component = new TwoFactorAppStep1Component(new UserPreferenceService(new HttpClientMock() as any), new NotificationServiceMock() as any, new ChangeDetectorRefMock() as any);
  });
  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('onNavigateNext', () => {
    it('should be able to navigate to the next page', () => {
      component.onNavigateNext().then((val) => {
        expect(val).toBeTruthy();
      });
    });
  });
});
