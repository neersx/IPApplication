// tslint:disable: no-floating-promises
import { async } from '@angular/core/testing';
import { TwoFactorAppStep4Component } from './two-factor-app-step4.component';

describe('TwoFactorAppStep4Component', () => {
  let component: TwoFactorAppStep4Component;

  beforeEach(async(() => {
    component = new TwoFactorAppStep4Component();
  }));

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
