import { animate, state, style, transition, trigger } from '@angular/animations';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';
import { AuthenticationService } from '../signin/authentication.service';
import { ResetPasswordService } from './resetpassword.service';

@Component({
  selector: 'resetpassword',
  templateUrl: './resetpassword.component.html',
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
export class ResetPasswordComponent implements OnInit {
  status = 'ready';
  systemInfo = {
    releaseYear: '',
    inprotechVersion: '',
    appVersion: ''
  };

  formData = {
    userName: '',
    oldPassword: '',
    newPassword: '',
    confirmPassword: '',
    error: '',
    errorFromServer: '',
    success: '',
    status: '',
    disableSendLinkFormControl: false,
    disableChangePsswordFormControl: false
  };

  cookieConsentSettings = {
    isConfigured: false,
    isResetConfigured: false,
    isVerificationConfigured: false
  };
  isExpired: boolean;
  token: string;
  culture: string;
  timeLeft: number;
  interval = null;
  passwordPolicyContent: Array<string>;

  constructor(private readonly router: Router, private readonly route: ActivatedRoute,
    private readonly service: ResetPasswordService,
    private readonly translate: TranslateService,
    private readonly authService: AuthenticationService,
    private readonly cdRef: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.route.queryParamMap.subscribe(params => {
      this.token = params.get('token');
      this.isExpired = params.get('isexpired') && params.get('isexpired') === '1';
      this.formData.userName = params.get('id');
      this.cdRef.markForCheck();
    });
    this.authService.getOptions().then((data) => {
      this.culture = data.userAgent.languages;
      this.setLocality(data.userAgent.languages, data.resource);
      this.systemInfo = { ...data.systemInfo };
      this.cookieConsentSettings = { ...data.signInOptions.cookieConsent };

      this.passwordPolicyContent = [
        data.resource.passwordPolicyContentAtLeastEightCharacters,
        data.resource.passwordPolicyContentAtLeastOneSpecialCharacter,
        data.resource.passwordPolicyContentAtLeastOneUpperAndLowerCase,
        data.resource.passwordPolicyContentAtLeastOneNumericValue
      ];

      this.cdRef.markForCheck();
    }, () => {
      this.status = 'error';
      this.cdRef.markForCheck();
    });
  }

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

  isCredentialValid = () => {
    if (!this.formData.userName) {
      this.formData.error = 'requiredLoginId';
      this.formData.success = '';

      return false;
    }

    return true;
  };

  cancel = () => {
    this.clearError();
    this.router.navigateByUrl('');
  };

  send = () => {
    if (!this.cookieConsentRequired()) {
      return;
    }

    if (!this.isCredentialValid()) {
      return;
    }
    this.sendEmail();
  };

  private readonly sendEmail = () => {
    this.clearError();
    this.service.sendEmail(this.formData.userName, window.location.href)
      .subscribe((result) => {
        if (result.status === 'success') {
          this.translate.get('emailSent').subscribe(res => {
            this.navigateWithTimeInterval(res);
            this.formData.userName = '';
            this.formData.disableSendLinkFormControl = true;
          });
        } else {
          this.formData.error = result.status;
        }
      }, () => {
        this.formData.error = 'resetPasswordFailed';
        this.cdRef.markForCheck();
      }, () => {
        this.cdRef.markForCheck();
      });
  };

  private readonly navigateWithTimeInterval = (message: string, totalTimeInSeconds = 10): void => {
    this.timeLeft = totalTimeInSeconds;
    this.interval = setInterval(() => {
      if (this.timeLeft > 0) {
        this.formData.success = this.formatString(message, this.timeLeft.toString());
        this.cdRef.markForCheck();
        this.timeLeft--;
      } else {
        clearInterval(this.interval);
        this.router.navigate(['']);
      }
    }, 1000);
  };

  private readonly formatString = (str: string, ...val: Array<string>): string => {
    let replacedStr = str;
    for (let index = 0; index < val.length; index++) {
      replacedStr = replacedStr.replace(`{${index}}`, val[index]);
    }

    return replacedStr;
  };

  clearError = () => {
    this.formData.error = undefined;
    this.formData.errorFromServer = undefined;
    this.formData.success = '';
    this.formData.status = '';
    this.formData.errorFromServer = undefined;
    this.cdRef.markForCheck();

    return true;
  };

  showChangePasswordPanel = (): boolean => {
    return this.token !== null;
  };

  save = () => {
    this.clearError();

    if (!this.cookieConsentRequired()) {
      return;
    }
    if (!this.validateResetPassword()) {
      return;
    }

    this.service.updatePassword(this.token, this.formData.newPassword, this.formData.confirmPassword, this.formData.oldPassword, this.isExpired)
      .subscribe(result => {
        switch (result.status) {
          case 'success':
            this.translate.get('resetPasswordSuccessful').subscribe(res => {
              this.navigateWithTimeInterval(res);
              this.formData.newPassword = this.formData.confirmPassword = this.formData.oldPassword = '';
              this.formData.disableChangePsswordFormControl = true;
            });
            break;
          case 'passwordPolicyValidationFailed':
            if (result.hasPasswordReused) {
              this.formData.error = result.passwordPolicyValidationErrorMessage;
            } else {
              this.formData.error = 'passwordPolicy-heading';
              this.formData.status = result.status;
            }
            break;
          default:
            this.formData.error = result.status;
            this.formData.status = result.status;
            break;
        }
        this.cdRef.markForCheck();
      }, () => {
        this.formData.errorFromServer = 'passwordNotUpdated';
        this.cdRef.markForCheck();
      });
  };

  validateResetPassword = () => {
    this.formData.success = '';
    if (this.isExpired && !this.formData.oldPassword) {
      this.formData.error = 'oldPasswordRequired';

      return false;
    }
    if (!this.formData.newPassword) {
      this.formData.error = 'newPasswordRequired';

      return false;
    }
    if (!this.formData.confirmPassword) {
      this.formData.error = 'confirmPasswordRequired';

      return false;
    }
    if (this.formData.newPassword !== this.formData.confirmPassword) {
      this.formData.error = 'passwordMismatch';

      return false;
    }

    return true;
  };

  changeDivColor = () => {
    if (this.formData.success) {
      return 'col-xs-8 col-sm-5 col-md-4 col-lg-3';
    }

    return 'col-xs-9 col-sm-5 col-md-4 col-lg-4';
  };

  private readonly cookieConsentRequired = (): boolean => {
    if (!this.cookieConsent.consented) {
      this.formData.error = 'cookieConsentRequired';
    }

    return this.cookieConsent.consented;
  };

  get cookieConsent(): { consented: boolean, preferenceConsented: boolean } {
    const defaultSetting = {
      consented: true,
      preferenceConsented: true
    };
    if (this.cookieConsentSettings.isVerificationConfigured) {
      const func = (window as any).inproCookieConsent;
      if (!!(func && func.constructor && func.call && func.apply)) {
        return { ...defaultSetting, ...func() };
      }
    }

    return defaultSetting;
  }

  trackByFn = (index: number, item: any) => {
    return index;
  };
}
