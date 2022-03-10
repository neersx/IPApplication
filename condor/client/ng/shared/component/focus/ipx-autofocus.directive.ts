import { AfterContentInit, Directive, ElementRef, HostBinding, Input } from '@angular/core';
import * as _ from 'underscore';
@Directive({
    selector: '[ipx-autofocus]'
})
export class AutoFocusDirective implements AfterContentInit {
    @HostBinding('attr.ipx-autofocus') @Input('ipx-autofocus') ipxAutoFocus: any;

    private inputElement: HTMLSelectElement | HTMLInputElement | HTMLTextAreaElement;

    constructor(private readonly element: ElementRef) {  }

    ngAfterContentInit(): void {
        setTimeout(() => {
            if (this.element && this.element.nativeElement) {
                this.inputElement = this.element.nativeElement.querySelector('input, textarea, select');
                if (!this.inputElement) {
                    this.inputElement = this.element.nativeElement;
                }
                if ((this.ipxAutoFocus === '' || this.ipxAutoFocus === 'true') && this.inputElement) {
                    let latency = 0;
                    if (document.querySelector('.modal-body')) {
                        latency = 800;
                    }
                    if (latency > 0) {
                        setTimeout(() => {
                            this.inputElement.focus();
                        }, latency);
                    } else {
                        this.inputElement.focus();
                    }
                }
            }
        }, 0);
    }
}