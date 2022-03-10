import { Type } from '@angular/core';
import { WizardStepComponent } from './wizard-step-component';

export class WizardItem {
  constructor(public component: Type<WizardStepComponent>, public data: { title: string }) { }
}
