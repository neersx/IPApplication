import { ChangeDetectorRefMock, TwoFactorAppConfigurationServiceMock } from 'mocks';
import { TwoFactorAppStep3Component } from './two-factor-app-step3.component';

describe('TwoFactorAppStep3Component', () => {
  let component: TwoFactorAppStep3Component;
  beforeEach(() => {
    component = new TwoFactorAppStep3Component(new TwoFactorAppConfigurationServiceMock() as any, new ChangeDetectorRefMock() as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
  describe('onNavigateNext', () => {
    it('should not navigate to next page with empty verifification code', () => {
      component.onNavigateNext().catch((reason) => {
        expect(reason).toEqual('twoFactorConfiguration.step3.codeRequired');
      });
    });

    it('should be call onNavigateNext function', () => {
      spyOn(component, 'onNavigateNext');
      component.onNavigateNext();
      expect(component.onNavigateNext).toHaveBeenCalled();
    });
  });
});
