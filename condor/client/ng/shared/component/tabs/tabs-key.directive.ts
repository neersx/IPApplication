import { Directive, Input, TemplateRef } from '@angular/core';

@Directive({
    selector: '[ipxTemplateTabKey]'
})
export class TemplateTabKeyDirective {
    @Input('ipxTemplateTabKey') key: string;
    @Input('title') title: string;
    constructor(public template: TemplateRef<any>) { }
}