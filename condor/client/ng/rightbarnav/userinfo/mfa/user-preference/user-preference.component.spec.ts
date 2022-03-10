// tslint:disable: no-floating-promises
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterTestingModule } from '@angular/router/testing';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { IpxRadioButtonGroupComponent } from 'shared/component/forms/ipx-radio-button-group/ipx-radio-button-group.component';
import { IpxRadioButtonComponent } from 'shared/component/forms/ipx-radio-button/ipx-radio-button.component';
import { WizardNavigationComponent } from 'shared/component/forms/wizard-navigation/wizard-navigation.component';
import { TranslatedServiceMock, TranslatePipeMock } from '../../../../../signin/src/app/mock/index.spec';
import { TwoFactorAppConfigurationComponent } from '../mfa-config/two-factor-app-configuration.component';
import { UserPreferenceComponent } from './user-preference.component';

describe('UserPreferenceComponent', () => {
  let component: UserPreferenceComponent;
  let fixture: ComponentFixture<UserPreferenceComponent>;
  const translate: TranslatedServiceMock = new TranslatedServiceMock();

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      providers: [{ provide: TranslateService, useValue: translate }, { provide: NotificationService, useValue: { succeed: jest.fn() } }],
      imports: [FormsModule, HttpClientTestingModule, RouterTestingModule.withRoutes([]), ReactiveFormsModule
      ],
      declarations: [UserPreferenceComponent, TranslatePipeMock, IpxRadioButtonComponent, IpxRadioButtonGroupComponent, WizardNavigationComponent, TwoFactorAppConfigurationComponent]
    })
      .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(UserPreferenceComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should set configure app mode to false on stopConfiguringApp()', () => {
    component.configureAppMode = true;
    component.stopConfiguringApp();

    expect(component.configureAppMode).toBeFalsy();
  });

  it('should set configure app mode to true on startConfiguringApp()', () => {
    component.configureAppMode = true;
    const clickEvent = {
      stopPropagation: jest.fn()
    };
    component.startConfiguringApp(clickEvent);

    expect(component.configureAppMode).toBeTruthy();
    expect(clickEvent.stopPropagation).toHaveBeenCalled();
  });
});
