import { ChangeDetectionStrategy, Component, EventEmitter, Output, ViewChild } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { WizardItem } from 'shared/component/forms/wizard-navigation/wizard-item';
import { WizardNavigationComponent } from 'shared/component/forms/wizard-navigation/wizard-navigation.component';
import { TwoFactorAppStep1Component } from './two-factor-app-step1/two-factor-app-step1.component';
import { TwoFactorAppStep2Component } from './two-factor-app-step2/two-factor-app-step2.component';
import { TwoFactorAppStep3Component } from './two-factor-app-step3/two-factor-app-step3.component';
import { TwoFactorAppStep4Component } from './two-factor-app-step4/two-factor-app-step4.component';

@Component({
  selector: 'two-factor-app-configuration',
  templateUrl: './two-factor-app-configuration.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TwoFactorAppConfigurationComponent {
  get step(): number {
    return this.wizard && this.wizard.currentStep;
  }

  steps: Array<WizardItem>;
  @Output() readonly onclose = new EventEmitter();
  @Output() readonly onsuccess = new EventEmitter();
  @ViewChild(WizardNavigationComponent, { static: true }) wizard: WizardNavigationComponent;

  constructor(private readonly notificationService: NotificationService) {
    this.steps = [
      new WizardItem(TwoFactorAppStep1Component, { title: 'twoFactorConfiguration.step1.stepHeading' }),
      new WizardItem(TwoFactorAppStep2Component, { title: 'twoFactorConfiguration.step2.stepHeading' }),
      new WizardItem(TwoFactorAppStep3Component, { title: 'twoFactorConfiguration.step3.stepHeading' }),
      new WizardItem(TwoFactorAppStep4Component, { title: 'twoFactorConfiguration.step4.stepHeading' })
    ];
  }

  proceed = () => {
    this.wizard.nextStep();
  };

  back = () => {
    this.wizard.previousStep();
  };

  allStepsComplete = () => {
    this.notificationService.success();
    this.onsuccess.emit();
  };

  cancel = () => {
    this.onclose.emit();
  };
}
