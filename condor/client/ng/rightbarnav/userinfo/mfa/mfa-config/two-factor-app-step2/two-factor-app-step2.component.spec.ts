// tslint:disable: no-floating-promises
import { ChangeDetectorRefMock, HttpClientMock } from 'mocks';
import { TwoFactorAppConfigurationService } from '../../two-factor-app-configuration.service';
import { TwoFactorAppStep2Component } from './two-factor-app-step2.component';

describe('TwoFactorAppStep2Component', () => {
  let component: TwoFactorAppStep2Component;

  beforeEach(() => {
    const httpMock = new HttpClientMock();
    httpMock.get.mockReturnValue({
      subscribe: (() => ({}))
    });
    component = new TwoFactorAppStep2Component(new TwoFactorAppConfigurationService(httpMock as any), new ChangeDetectorRefMock() as any);
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
