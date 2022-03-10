// tslint:disable: no-floating-promises
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { RouterTestingModule } from '@angular/router/testing';
import { TranslateService } from '@ngx-translate/core';

import { TranslatedServiceMock, TranslatePipeMock } from '../../../../../signin/src/app/mock/index.spec';

import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { TwoFactorAppStep1Component } from 'rightbarnav/userinfo/mfa/mfa-config/two-factor-app-step1/two-factor-app-step1.component';
import { WizardComponentHostDirective } from './wizard-component-host.directive';
import { WizardItem } from './wizard-item';
import { WizardNavigationComponent } from './wizard-navigation.component';

describe('WizardNavigationComponent', () => {
  let component: WizardNavigationComponent;
  let fixture: ComponentFixture<WizardNavigationComponent>;
  const translate: TranslatedServiceMock = new TranslatedServiceMock();

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      providers: [{ provide: TranslateService, useValue: translate }, { provide: NotificationService, useValue: { succeed: jest.fn() } }],
      imports: [FormsModule, HttpClientTestingModule, RouterTestingModule.withRoutes([])],
      declarations: [WizardNavigationComponent, TranslatePipeMock, TwoFactorAppStep1Component, WizardComponentHostDirective]
    }).overrideModule(FormsModule, {
      set: {
        entryComponents: [
          TwoFactorAppStep1Component
        ]
      }
    })
      .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(WizardNavigationComponent);
    component = fixture.componentInstance;
    component.steps = [
      new WizardItem(TwoFactorAppStep1Component, { title: '' }),
      new WizardItem(TwoFactorAppStep1Component, { title: '' }),
      new WizardItem(TwoFactorAppStep1Component, { title: '' }),
      new WizardItem(TwoFactorAppStep1Component, { title: '' }),
      new WizardItem(TwoFactorAppStep1Component, { title: '' })
    ];
    fixture.detectChanges();
  });

  it('should create and defult step to equal 1', () => {
    expect(component).toBeTruthy();
    expect(component.currentStep).toEqual(1);
  });

  it('should not be able to go step 0', async(() => {
    component.previousStep();
    fixture.whenStable().then(() => {
      expect(component.currentStep).toEqual(1);
    });
  }));

  it('should not be able to go beyond bounds of the step list', async(() => {
    component.nextStep();
    component.nextStep();
    component.nextStep();
    component.nextStep();
    component.nextStep();
    component.nextStep();
    component.nextStep();
    fixture.whenStable().then(() => {
      expect(component.currentStep).toEqual(4);
    });
  }));
});
