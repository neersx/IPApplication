import { Directive, ElementRef, Injector } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';

@Directive({
    selector: 'ip-resize-handler-upg'
})
export class ResizeHandlerDirective extends UpgradeComponent {
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipResizeHandlerWrapper', elementRef, injector);
    }
}
