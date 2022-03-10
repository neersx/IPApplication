import { ChangeDetectionStrategy, Component, ElementRef, Input, OnInit } from '@angular/core';

@Component({
    selector: '[one-time-bind]',
    template: '',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class OneTimeBindComponent implements OnInit {
    @Input('one-time-bind') property: { [propName: string]: any };
    constructor(private readonly element: ElementRef) { }

    ngOnInit(): void {
        Object.keys(this.property).forEach(key => {
            this.element.nativeElement.setAttribute(key, this.property[key]);
        });

    }
}