import { Directive, ViewContainerRef } from '@angular/core';

@Directive({
  selector: '[model-host]'
})
export class IpxPicklistModelHostDirective {
  constructor(public viewContainerRef: ViewContainerRef) { }
}
