import { Directive, ViewContainerRef } from '@angular/core';

@Directive({
  selector: '[wizardComponentHost]'
})
export class WizardComponentHostDirective {
  constructor(public viewContainerRef: ViewContainerRef) { }
}
