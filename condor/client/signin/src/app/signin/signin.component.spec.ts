import { HttpClientTestingModule } from '@angular/common/http/testing';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { RouterTestingModule } from '@angular/router/testing';
import { TranslateService } from '@ngx-translate/core';

// tslint:disable-next-line: import-blacklist
import { of } from 'rxjs';
import { ActivatedRouteStub } from '../mock/activate-route.mock';
import { AuthenticationService } from './authentication.service';
import { SigninComponent } from './signin.component';

import { TranslatedServiceMock, TranslatePipeMock } from '../mock/index.spec';

describe('SigninComponent', () => {
  let component: SigninComponent;
  let translate: TranslatedServiceMock;
  let fixture: ComponentFixture<SigninComponent>;
  let authenticationServiceStub;
  const options = {
    userAgent: {
      languages: ['en', 'en-AU']
    },
    systemInfo: {
      releaseYear: '',
      inprotechVersion: '',
      appVersion: ''
    },
    signInOptions: {
      showForms: false,
      showWindows: false,
      showSso: false,
      showAdfs: false,
      currentAuthMode: ''
    }
  };

  const signinResponse = {
    status: 'codeRequired',
    returnUrl: 'http://localhost/cpaimproma/#/home',
    configuredTwoFactorAuthModes: ['email', 'app'],
    failReasonCode: '',
    error: ''
  };

  beforeEach(async(() => {
    translate = new TranslatedServiceMock();
    const routerSpy = { navigate: jest.fn() };
    authenticationServiceStub = { getOptions: jest.fn(r => of(options).toPromise()), signin: jest.fn(r => of(signinResponse).toPromise()) };
    TestBed.configureTestingModule({
      providers: [{ provide: ActivatedRoute, useValue: { queryParams: of({ goto: 'http://localhost/cpaimproma/dashboard' }) } },
      { provide: Router, useValue: routerSpy },
      { provide: TranslateService, useValue: translate },
      { provide: AuthenticationService, useValue: authenticationServiceStub }],
      imports: [FormsModule, HttpClientTestingModule, RouterTestingModule.withRoutes([])],
      declarations: [SigninComponent, TranslatePipeMock]
    })
      .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SigninComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    fixture.detectChanges();
    expect(component).toBeTruthy();
    expect(component.methods).toEqual(options.signInOptions);
    expect(component.systemInfo).toEqual(options.systemInfo);
  });

  it('should set locality', () => {
    expect(component.status).toBe('ready');
    expect(translate.language).toBe('en');
    expect(translate.languages).toBe(options.userAgent.languages);
  });

  it('should signin', () => {
    component.data = {
      username: 'user',
      password: 'password',
      error: '',
      errorFromServer: '',
      configuredTwoFactorAuthModes: []
    };
    component.signIn();
    fixture.whenStable().then(() => {
      expect(component.data.configuredTwoFactorAuthModes).toEqual(signinResponse.configuredTwoFactorAuthModes);
      expect(component.methods.currentAuthMode).toEqual(signinResponse.configuredTwoFactorAuthModes[0]);
    }).catch();
  });

  it('should change preference', () => {
    component.data = {
      username: 'user',
      password: 'password',
      error: '',
      errorFromServer: '',
      configuredTwoFactorAuthModes: []
    };
    component.signIn();
    fixture.whenStable().then(() => {
      expect(component.methods.currentAuthMode).toBe(signinResponse.configuredTwoFactorAuthModes[0]);
      component.changePreference();
      fixture.whenStable().then(() => {
        expect(component.methods.currentAuthMode).toBe(signinResponse.configuredTwoFactorAuthModes[1]);
      }).catch();
    });
  });

  it('should should call the set method if statistics consented', () => {
    component.cookieConsentSettings.isVerificationConfigured = true;
    (window as any).inproCookieConsent = () => ({
      statisticsConsented: true
    });

    const setSpy = jest.spyOn(Storage.prototype, 'setItem');
    const removeSpy = jest.spyOn(Storage.prototype, 'removeItem');
    (component as any).setStatisticsConsent();

    expect(removeSpy).not.toHaveBeenCalled();
    expect(setSpy).toHaveBeenCalledWith('statisticsConsented', '1');
    removeSpy.mockClear();
    setSpy.mockClear();
  });

  it('should should call the remove method if statistics consented', () => {
    const removeSpy = jest.spyOn(Storage.prototype, 'removeItem');
    const setSpy = jest.spyOn(Storage.prototype, 'setItem');
    component.cookieConsentSettings.isVerificationConfigured = true;
    (window as any).inproCookieConsent = () => ({
      statisticsConsented: false
    });

    (component as any).setStatisticsConsent();

    expect(setSpy).not.toHaveBeenCalled();
    expect(removeSpy).toHaveBeenCalledWith('statisticsConsented');
    removeSpy.mockClear();
    setSpy.mockClear();
  });
});
