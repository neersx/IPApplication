import { ChangeDetectionStrategy, Component, EventEmitter } from '@angular/core';
import { WizardStepComponent } from 'shared/component/forms/wizard-navigation/wizard-step-component';

@Component({
  selector: 'two-factor-app-step4',
  templateUrl: './two-factor-app-step4.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TwoFactorAppStep4Component implements WizardStepComponent {
  cancel = new EventEmitter<any>();
  title: string;
  onNavigateNext = () => new Promise<boolean>((resolve, reject): void => {
    resolve(true);
  });
}
