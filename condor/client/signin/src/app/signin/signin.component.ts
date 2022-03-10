// tslint:disable:max-file-line-count
import { animate, state, style, transition, trigger } from '@angular/animations';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, NgZone, OnDestroy, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';
import { BehaviorSubject } from 'rxjs';
import { AuthenticationService } from './authentication.service';

@Component(
  {
    templateUrl: './signin.component.html',
    animations: [
      trigger('toggle', [
        state('true', style({ opacity: 1 })),
        state('void', style({ opacity: 0 })),
        transition(':enter', animate('500ms ease-in-out')),
        transition(':leave', animate('200ms ease-in-out'))
      ])
    ],
    changeDetection: ChangeDetectionStrategy.OnPush
  })

export class SigninComponent implements OnInit, OnDestroy {
  status = 'ready';
  criticalErrorOccurred = false;
  resentStatus = {
    canResend: true,
    countdown: 30,
    intervalId: null,
    countdownMessage: null
  };
  readonly twoFactorModesString = {
    app: 'app',
    email: 'email',
    codeError: 'two-factor-failed'
  };
  info = {
    header: '',
    formsAuthString: '',
    windowsAuthString: '',
    ssoAuthString: '',
    data: '',
    systemInfo: '',
    isVisible: false,
    hideAlways: ''
  };
  data = {
    username: '',
    password: '',
    error: '',
    errorFromServer: '',
    configuredTwoFactorAuthModes: []
  };

  authenticationCode: '';
  systemInfo = {
    releaseYear: '',
    inprotechVersion: '',
    appVersion: ''
  };

  methods = {
    showForms: false,
    showWindows: false,
    showSso: false,
    showAdfs: false,
    currentAuthMode: ''
  };

  private readonly storageKeys = {
    key: 'signin',
    authMode: 'authMode',
    authModeTemp: 'authModeTemp',
    preferenceConsented: 'preferenceConsented',
    statisticsConsented: 'statisticsConsented',
    firmConsentedToUserStatistics: 'firmConsentedToUserStatistics'
  };
  private readonly authModes = {
    forms: 1,
    windows: 2,
    sso: 3,
    adfs: 4
  };
  private readonly url = {
    baseUrl: '../',
    api: (url: string) => ('../' + 'api/' + url)
  };

  cookieConsentSettings = {
    isConfigured: false,
    isResetConfigured: false,
    isVerificationConfigured: false
  };

  private sub: any;
  private params: any;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly translate: TranslateService,
    private readonly service: AuthenticationService,
    private readonly zone: NgZone,
    private readonly cdRef: ChangeDetectorRef
  ) {
  }

  ngOnDestroy(): void {
    this.sub.unsubscribe();
  }

  ngOnInit(): void {
    this.sub = this.route
      .queryParams
      .subscribe(parameters => {
        this.params = parameters;
      });

    this.service.getOptions().then((data) => {
      this.setLocality(data.userAgent.languages, data.resource);
      this.systemInfo = { ...data.systemInfo };
      this.methods = { ...data.signInOptions };
      this.cookieConsentSettings = { ...data.signInOptions.cookieConsent };

      if (data.signInOptions.firmConsentedToUserStatistics) {
        this.setSessionAndLocalStorage(this.storageKeys.firmConsentedToUserStatistics, '1');
      } else {
        this.removeSessionAndLocalStorage(this.storageKeys.firmConsentedToUserStatistics);
      }

      this.methods.showWindows = !this.methods.showAdfs && this.methods.showWindows;

      this.autoLoginOOB();

      if (this.params.errorCode) {
        this.clearAuthMode();
        this.setServerError();
        this.status = 'ready';
      }

      if (!this.autoLoginIfApplicable()) {
        this.initInfoDisplay();
        this.status = 'ready';
      }
      this.cdRef.markForCheck();
    }, (response: any) => {
      this.status = 'error';
      this.data.errorFromServer = 'An error occurred. Contact your Administrator.';
      this.criticalErrorOccurred = true;
      this.cdRef.markForCheck();
    });
  }

  signIn = () => {
    this.clearStatus();
    this.clearCodeStatus();

    if (!this.cookieConsentRequired()) {
      return;
    }

    if (!this.isCredentialValid()) {
      return;
    }
    this.shouldInfoBeHiddenAlways();
    this.authenticate();
  };

  verifyCodeAndSignin = () => {
    this.authenticate();
  };

  resendCode = () => {
    if (!this.isCredentialValid()) {
      return;
    }
    this.authenticationCode = '';
    this.authenticate();
  };

  changePreference = () => {
    this.authenticationCode = '';
    if (this.data.configuredTwoFactorAuthModes.length > 1 && this.methods.currentAuthMode) {
      switch (this.methods.currentAuthMode) {
        case this.twoFactorModesString.app: {
          this.authenticate(this.twoFactorModesString.email.toString());
          break;
        }
        case this.twoFactorModesString.email: {
          this.authenticate(this.twoFactorModesString.app.toString());
          break;
        }
        default: {
          break;
        }
      }
    }
  };

  cancelCode = (): boolean => {
    this.clearError();
    this.methods.currentAuthMode = '';

    return true;
  };

  windowsSignIn = () => {
    this.clearStatus();
    this.status = 'loading';
    this.shouldInfoBeHiddenAlways();

    const redirectUrl = encodeURIComponent(this.params.goto || '' as string);
    this.service.signinWindows(this.url.api('../../winAuth/endpoint?redirectUrl=' + redirectUrl))
      .toPromise()
      .then((response: any) => {
        if (response.status === 'success') {
          this.storeAuthMode(this.authModes.windows);
        }
        this.loginActions(response);
        this.cdRef.markForCheck();
      }, (response: any) => {
        this.status = 'error';
        this.data.errorFromServer = response.error.status || this.status;
        this.cdRef.markForCheck();
      });
  };

  ssoSignIn = () => {
    this.clearStatus();
    this.status = 'loading';
    this.shouldInfoBeHiddenAlways();
    this.storeAuthModeTemp(this.authModes.sso);

    const redirectUrl = encodeURIComponent(this.params.goto || '' as string);

    this.navigateTo(this.url.api('signin') + '/initiateSso?redirectUrl=' + redirectUrl);
  };

  adfsSignIn = () => {
    this.clearStatus();
    this.status = 'loading';
    this.shouldInfoBeHiddenAlways();
    this.storeAuthModeTemp(this.authModes.adfs);

    const redirectUrl = encodeURIComponent(this.params.goto || '' as string);

    this.navigateTo(this.url.api('signin') + '/adfs?redirectUrl=' + redirectUrl);
  };

  layoutWidthClass = () => {
    if ((this.methods.showWindows || this.methods.showSso || this.methods.showAdfs) && this.methods.showForms) {
      return 'col-xs-9 col-sm-8 col-md-7 col-lg-5';
    }

    if (this.methods.showForms && !(this.methods.showWindows || this.methods.showSso || this.methods.showAdfs)) {
      return 'col-xs-8 col-sm-5 col-md-4 col-lg-3';
    }

    return 'col-xs-9 col-sm-5 col-md-4 col-lg-4';
  };

  hideInfo = () => {
    this.info.isVisible = false;
    this.shouldInfoBeHiddenAlways();
  };

  clearStatus = () => {
    this.clearError();
    this.authenticationCode = '';
    this.clearAuthMode();
  };
  clearError = () => {
    this.data.error = undefined;
    this.data.errorFromServer = undefined;

    return true;
  };

  resetCookiePrefrences = () => {
    const func = (window as any).inproShowCookieBanner;
    if (!!(func && func.constructor && func.call && func.apply)) {
      func();
    }
  };

  private readonly setLocality = (culture: Array<string>, translations: any) => {
    // tslint:disable-next-line: no-parameter-reassignment
    culture = culture || ['en'];
    this.translate.addLangs(culture);
    this.translate.setDefaultLang('en');
    culture.forEach((cult) => {
      this.translate.setTranslation(cult, translations, true);
    });
    this.translate.use(culture[0]);
  };

  private readonly setResendTimeout = () => {
    this.resentStatus.canResend = false;
    this.resentStatus.countdown = 30;
    this.resentStatus.intervalId = setInterval(() => {
      this.resentStatus.countdown -= 1;
      if (this.resentStatus.countdown === 0) {
        this.resentStatus.canResend = true;
        clearInterval(this.resentStatus.intervalId);
      } else {
        if (this.resentStatus.countdown < 0) {
          this.resentStatus.countdown = 0;
        }
      }

      this.zone.run(() => {
        this.resentStatus.countdownMessage.next(this.resentStatus.countdown === 0 ? ''
          : '( ' + this.resentStatus.countdown + this.translate.instant('seconds') + ' )');
      });
    }, 1000);
  };
  private readonly autoLoginOOB = () => {
    if (!this.params.oobAuthMode) {

      return;
    }
    if (this.methods.showForms && this.params.oobAuthMode === this.authModes.forms.toString()) {
      this.methods.showSso = false;
      this.methods.showAdfs = false;
      this.methods.showWindows = false;
    }
    if (this.methods.showWindows && this.params.oobAuthMode === this.authModes.windows.toString()) {
      this.methods.showSso = false;
      this.methods.showAdfs = false;
      this.methods.showForms = false;
    }
  };

  private readonly authenticate = (authMode?: string) => {
    this.status = 'loading';
    this.clearError();

    this.service.signin(this.url.api('signin'),
      this.data.username,
      this.data.password,
      this.params.goto || '' as string,
      this.authenticationCode,
      authMode || this.methods.currentAuthMode
    )
      .then((response: any) => {
        if (authMode) {
          this.methods.currentAuthMode = authMode;
        }
        this.loginActions(response);
        this.cdRef.markForCheck();
      }, (response: any) => {
        this.status = 'error';
        this.data.errorFromServer = response.error.status;
        this.cdRef.markForCheck();
      });
  };

  private readonly autoLoginIfApplicable = () => {
    if (this.params.errorCode) {

      return false;
    }

    if (this.methods.showSso && (!(this.methods.showWindows || this.methods.showForms) || this.isAuthMethodSaved(this.authModes.sso))) {
      this.ssoSignIn();

      return true;
    }
    if (this.methods.showWindows && (!(this.methods.showSso || this.methods.showForms) || this.isAuthMethodSaved(this.authModes.windows))) {
      this.windowsSignIn();

      return true;
    }

    if (this.methods.showAdfs && (!(this.methods.showSso || this.methods.showForms) || this.isAuthMethodSaved(this.authModes.adfs))) {
      this.adfsSignIn();

      return true;
    }

    return false;
  };

  private readonly isCredentialValid = () => {
    if (!this.data.username && !this.data.password) {
      this.data.error = 'credentialRequired';

      return false;
    }

    if (!this.data.username) {
      this.data.error = 'usernameRequired';

      return false;
    }

    if (!this.data.password) {
      this.data.error = 'passwordRequired';

      return false;
    }

    return true;
  };

  private shouldInfoBeHiddenAlways(): void {
    if (this.info.hideAlways) {
      const infoHash = this.getCurrentInfoHash();
      this.setSigninStorageItem('hideInfoWhenLabelHashIs', infoHash);
    }
  }

  private readonly initInfoDisplay = () => {
    const authModeCount = (+ this.methods.showForms) + (+ this.methods.showSso) + + (this.methods.showAdfs || this.methods.showWindows);
    if (authModeCount === 1) {
      this.info.isVisible = false;
    } else {
      this.info.header = this.getTranslatedText('infoHeader');
      this.info.formsAuthString = this.methods.showForms ? this.getTranslatedText('infoForFormsAuth') : undefined;

      const windowsAuthString = this.methods.showWindows ? this.getTranslatedText('infoForWindowsAuth') : undefined;
      const adfsAuthString = this.methods.showAdfs ? this.getTranslatedText('infoForAdfsAuth') : undefined;
      this.info.windowsAuthString = this.methods.showAdfs ? adfsAuthString : this.methods.showWindows ? windowsAuthString : undefined;

      this.info.ssoAuthString = this.methods.showSso ? this.getTranslatedText('infoForTheIpPlatformAuth') : undefined;

      if (!(this.info.formsAuthString || this.info.windowsAuthString || this.info.ssoAuthString)) {
        this.info.isVisible = false;

        return;
      }

      const storedLabelHash = this.getSigninStorageItem('hideInfoWhenLabelHashIs');

      this.info.isVisible = (storedLabelHash) ? storedLabelHash !== this.getCurrentInfoHash() : true;
    }
  };

  private readonly getTranslatedText = (key: string) => {
    const translatedText = this.translate.instant(key);

    return translatedText === '{blank}' ? undefined : translatedText;
  };

  private readonly getCurrentInfoHash = () => {
    let infoText = '';
    infoText += this.methods.showForms ? this.info.formsAuthString || '' as string : '';
    infoText += this.methods.showWindows ? this.info.windowsAuthString || '' as string : '';
    infoText += this.methods.showSso ? this.info.ssoAuthString || '' as string : '';
    infoText += infoText !== '' ? this.info.header : '';

    return infoText;
  };

  private readonly isAuthMethodSaved = (authenticationMethod: any): boolean => {
    const storedAuthMode = this.getSigninStorageItem(this.storageKeys.authMode);

    return storedAuthMode && storedAuthMode === authenticationMethod;
  };

  private readonly setServerError = () => {
    const errorCode = decodeURIComponent(this.params.errorCode);
    const errorParam = this.params.param ? decodeURIComponent(this.params.param) : undefined;
    this.data.errorFromServer = errorParam ? this.translate.instant(errorCode, { param: errorParam }) : this.translate.instant(errorCode);

    if (this.data.errorFromServer) {
      this.router.navigate([], { queryParams: { errorCode: undefined }, queryParamsHandling: 'merge' });
    }
  };

  private readonly storeAuthModeTemp = (authenticationMethodTemp: any) => {
    this.setSigninStorageItem(this.storageKeys.authMode, undefined);
    this.setSigninStorageItem(this.storageKeys.authModeTemp, authenticationMethodTemp);
  };

  private readonly storeAuthMode = (authenticationMethodTemp: any) => {
    this.setSigninStorageItem(this.storageKeys.authModeTemp, undefined);
    this.setSigninStorageItem(this.storageKeys.authMode, authenticationMethodTemp);
  };
  private readonly clearCodeStatus = () => {
    this.authenticationCode = '';
    this.methods.currentAuthMode = '';
  };

  private readonly clearAuthMode = () => {
    this.setSigninStorageItem(this.storageKeys.authMode, undefined);
    this.setSigninStorageItem(this.storageKeys.authModeTemp, undefined);
  };

  private getSigninStorageItem(key: string): string {
    const obj = localStorage.getItem(this.storageKeys.key);
    if (obj) {

      return JSON.parse(obj)[key];
    }

    return undefined;
  }
  private setSigninStorageItem(key: string, value: string): void {
    const obj = localStorage.getItem(this.storageKeys.key) || '{}';
    const signinObj = JSON.parse(obj);
    signinObj[key] = value;
    localStorage.setItem(this.storageKeys.key, JSON.stringify(signinObj));
  }

  private readonly navigateTo = (url: string): void => {
    window.location.href = url;
  };

  private readonly loginActions = (data: any) => {
    if (data.status === 'success') {
      this.setPreferenceConsent();
      this.setStatisticsConsent();

      if (data.returnUrl) {
        this.navigateTo(data.returnUrl);
      } else {
        this.navigateTo(this.url.baseUrl + '#/home');
      }
    } else if (data.status === 'codeRequired') {
      if (data.configuredTwoFactorAuthModes) {
        this.data.configuredTwoFactorAuthModes = [...data.configuredTwoFactorAuthModes];
        if (!this.methods.currentAuthMode) {
          this.methods.currentAuthMode = data.configuredTwoFactorAuthModes[0];
        }
      }
      if (this.methods.currentAuthMode === this.twoFactorModesString.email) {
        this.resentStatus.countdownMessage = new BehaviorSubject<string>('');
        this.zone.runOutsideAngular(() => {
          this.setResendTimeout();
        });
      }
    } else if (data.status === 'resetPassword') {
      if (data.returnUrl) {
        this.navigateTo(data.returnUrl + '&isexpired=1');
      }
    } else {
      let failReason = data.status;
      if (data.failReasonCode) {
        failReason = data.parameter ? this.translate.instant(data.failReasonCode, { param: data.parameter })
          : this.translate.instant(data.failReasonCode);

        if (data.failReasonCode !== this.twoFactorModesString.codeError) {
          this.clearCodeStatus();
        }
      }
      this.status = 'error';
      this.data.error = failReason;
    }
    this.status = 'ready';
  };

  private readonly setPreferenceConsent = () => {
    if (this.cookieConsent.preferenceConsented) {
      localStorage.setItem(this.storageKeys.preferenceConsented, '1');
    } else {
      localStorage.removeItem(this.storageKeys.preferenceConsented);
    }
  };

  private readonly setStatisticsConsent = () => {
    if (this.cookieConsent.statisticsConsented) {
      this.setSessionAndLocalStorage(this.storageKeys.statisticsConsented, '1');
    } else {
      this.removeSessionAndLocalStorage(this.storageKeys.statisticsConsented);
    }
  };

  private readonly setSessionAndLocalStorage = (key: string, value: string) => {
    sessionStorage.setItem(key, value);
    localStorage.setItem(key, value);
  };

  private readonly removeSessionAndLocalStorage = (key: string) => {
    sessionStorage.removeItem(key);
    localStorage.removeItem(key);
  };

  private readonly cookieConsentRequired = (): boolean => {
    if (!this.cookieConsent.consented) {
      this.data.error = 'cookieConsentRequired';
    }

    return this.cookieConsent.consented;
  };

  get cookieConsent(): { consented: boolean, preferenceConsented: boolean, statisticsConsented: boolean } {
    const defaultSetting = {
      consented: true,
      preferenceConsented: true,
      statisticsConsented: false
    };
    if (this.cookieConsentSettings.isVerificationConfigured) {
      const func = (window as any).inproCookieConsent;
      if (!!(func && func.constructor && func.call && func.apply)) {
        return { ...defaultSetting, ...func() };
      }
    }

    return defaultSetting;
  }
}
