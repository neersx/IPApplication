import { Directive, Input, OnInit, TemplateRef } from '@angular/core';
import * as _ from 'underscore';

@Directive({
    selector: '[ipxTemplateName]'
})
export class TemplateNameDirective implements OnInit {
    @Input('ipxTemplateName') name: string;

    constructor(public template: TemplateRef<any>) {
    }

    ngOnInit(): void {
        _.extend(this.template, {
            name: this.name
        });
    }
}