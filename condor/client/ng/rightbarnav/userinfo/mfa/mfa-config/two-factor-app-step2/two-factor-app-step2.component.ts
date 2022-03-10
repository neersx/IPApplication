// tslint:disable: no-floating-promises
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter } from '@angular/core';
import { WizardStepComponent } from 'shared/component/forms/wizard-navigation/wizard-step-component';
import { TwoFactorAppConfigurationService } from '../../two-factor-app-configuration.service';

@Component({
  selector: 'two-factor-app-step2',
  templateUrl: './two-factor-app-step2.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TwoFactorAppStep2Component implements WizardStepComponent {
  cancel = new EventEmitter<any>();
  title: string;
  twoFactorAppKey = '';
  qrCodeValue = '';
  constructor(private readonly service: TwoFactorAppConfigurationService,
    private readonly cdRef: ChangeDetectorRef) {
    service.GetTwoFactorTempKey().subscribe((key) => {
      this.twoFactorAppKey = key;
      this.qrCodeValue = 'otpauth://totp/Inprotech?secret=' + encodeURIComponent(this.twoFactorAppKey) + '&issuer=' + encodeURIComponent('CPA Global');
      this.cdRef.markForCheck();
    });
  }

  onNavigateNext = () => new Promise<boolean>((resolve, reject) => {
    resolve(true);
    this.cdRef.markForCheck();
  });
}
