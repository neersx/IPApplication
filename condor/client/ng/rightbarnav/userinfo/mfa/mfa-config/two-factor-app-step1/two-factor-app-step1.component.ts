import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { WizardStepComponent } from 'shared/component/forms/wizard-navigation/wizard-step-component';
import { UserPreferenceService } from '../../user-preference.service';

@Component({
  selector: 'two-factor-app-step1',
  templateUrl: './two-factor-app-step1.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TwoFactorAppStep1Component implements WizardStepComponent {
  cancel = new EventEmitter<any>();
  errorMessage: string;
  title: string;
  constructor(private readonly service: UserPreferenceService,
    private readonly notificationService: NotificationService,
    private readonly cdRef: ChangeDetectorRef) {
  }
  onNavigateNext = () => new Promise<boolean>((resolve, reject): void => {
    resolve(true);
    this.cdRef.markForCheck();
  });
  removeExistingConfiguration = () => {
    this.service.RemoveTwoFactorAppConfiguration().then(() => {
      this.notificationService.success();
      this.cancel.emit();
      this.cdRef.markForCheck();
    }).catch((e) => {
      this.errorMessage = e;
    });
  };
}
