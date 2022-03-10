import { Directive, ViewContainerRef } from '@angular/core';

@Directive({
  selector: '[topic-host]'
})
export class IpxTopicHostDirective {
  constructor(public viewContainerRef: ViewContainerRef) { }
}
