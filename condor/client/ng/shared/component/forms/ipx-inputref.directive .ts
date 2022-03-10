import { Directive, ElementRef, OnInit } from '@angular/core';

@Directive({
    selector: '[inputRef]'
})
export class InputRefDirective {
    constructor(public elementRef: ElementRef) {
    }
}