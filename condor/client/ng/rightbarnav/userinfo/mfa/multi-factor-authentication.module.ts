import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { ReactiveFormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { QRCodeModule } from 'angularx-qrcode';
import { SharedModule } from 'shared/shared.module';

import { TwoFactorAppConfigurationComponent } from './mfa-config/two-factor-app-configuration.component';
import { TwoFactorAppStep1Component } from './mfa-config/two-factor-app-step1/two-factor-app-step1.component';
import { TwoFactorAppStep2Component } from './mfa-config/two-factor-app-step2/two-factor-app-step2.component';
import { TwoFactorAppStep3Component } from './mfa-config/two-factor-app-step3/two-factor-app-step3.component';
import { TwoFactorAppStep4Component } from './mfa-config/two-factor-app-step4/two-factor-app-step4.component';
import { TwoFactorAppConfigurationService } from './two-factor-app-configuration.service';
import { UserPreferenceService } from './user-preference.service';
import { UserPreferenceComponent } from './user-preference/user-preference.component';

@NgModule({
  declarations: [
    UserPreferenceComponent,
    TwoFactorAppConfigurationComponent,
    TwoFactorAppStep1Component,
    TwoFactorAppStep2Component,
    TwoFactorAppStep3Component,
    TwoFactorAppStep4Component
  ],
  providers: [
    UserPreferenceService,
    TwoFactorAppConfigurationService
  ],
  exports: [UserPreferenceComponent],
  imports: [
    CommonModule,
    TranslateModule,
    ReactiveFormsModule,
    SharedModule,
    QRCodeModule,
    TranslateModule
  ],
  entryComponents: [
    UserPreferenceComponent,
    TwoFactorAppConfigurationComponent,
    TwoFactorAppStep1Component,
    TwoFactorAppStep2Component,
    TwoFactorAppStep3Component,
    TwoFactorAppStep4Component
  ]
})
export class MultiFactorAuthenticationModule { }
