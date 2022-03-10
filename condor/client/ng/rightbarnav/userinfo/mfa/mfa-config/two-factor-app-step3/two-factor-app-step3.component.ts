import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter } from '@angular/core';
import { WizardStepComponent } from 'shared/component/forms/wizard-navigation/wizard-step-component';
import { TwoFactorAppConfigurationService } from '../../two-factor-app-configuration.service';

@Component({
  selector: 'two-factor-app-step3',
  templateUrl: './two-factor-app-step3.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class TwoFactorAppStep3Component implements WizardStepComponent {
  cancel = new EventEmitter<any>();
  title: string;
  verifyCode = '';
  errorMessage = '';
  constructor(private readonly service: TwoFactorAppConfigurationService,
    private readonly cdRef: ChangeDetectorRef) {
  }
  onNavigateNext = () => new Promise<boolean>((resolve, reject): void => {
    this.errorMessage = '';
    if (this.verifyCode.length === 0) {
      this.errorMessage = 'twoFactorConfiguration.step3.codeRequired';
      reject(this.errorMessage);
    }
    this.service.VerifyAndSaveTempKey(this.verifyCode).then((res) => {
      switch (res.status) {
        case 'success':
          resolve(true);
          break;
        default:
          reject('twoFactorConfiguration.step3.invalidCode');
          break;
      }
      this.cdRef.markForCheck();
    }).catch(() => {
      reject('twoFactorConfiguration.step3.unexpectedError');
    });
  });
}
