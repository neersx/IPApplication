import { NotificationServiceMock } from 'mocks';
import { TwoFactorAppConfigurationComponent } from './two-factor-app-configuration.component';
describe('TwoFactorAppConfigurationComponent', () => {
  let component: TwoFactorAppConfigurationComponent;
  beforeEach(() => {
    component = new TwoFactorAppConfigurationComponent(NotificationServiceMock as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
  it('should be call back function', () => {
    spyOn(component, 'back');
    component.back();
    expect(component.back).toHaveBeenCalled();
  });
  it('should be call proceed function', () => {
    spyOn(component, 'proceed');
    component.proceed();
    expect(component.proceed).toHaveBeenCalled();
  });
  it('should be call allStepsComplete function', () => {
    spyOn(component, 'allStepsComplete');
    component.allStepsComplete();
    expect(component.allStepsComplete).toHaveBeenCalled();
  });

  it('should be call cancel function', () => {
    spyOn(component, 'cancel');
    component.cancel();
    expect(component.cancel).toHaveBeenCalled();
  });
});
