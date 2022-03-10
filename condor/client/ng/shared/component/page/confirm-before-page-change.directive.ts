import { Directive, HostListener, Input } from '@angular/core';

@Directive({
     selector: '[ipx-confirm-before-page-change]'
})
export class ConfirmBeforePageChangeDirective {
   @Input('ipx-confirm-before-page-change') shouldShowConfirm: any;
   @Input() confirmMessage: string;

   @HostListener('window:pagehide', ['$event']) beforeUnload($event): void {
      if (this.shouldShowConfirm) {
         $event.returnValue = this.confirmMessage;
     }
   }
}
