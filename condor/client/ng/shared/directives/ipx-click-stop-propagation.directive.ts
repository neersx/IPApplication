import { Directive, HostListener } from '@angular/core';

@Directive({
    selector: '[ipx-click-stop-propagation]'
})
export class IpxClickStopPropagationDirective {
    @HostListener('click', ['$event']) onClick(event: any): void {
        event.stopPropagation();
    }
}