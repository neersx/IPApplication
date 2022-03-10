import { Directive, Input, TemplateRef } from '@angular/core';

@Directive({
    selector: '[ipxTemplateColumnField]'
})
export class TemplateColumnFieldDirective {
    @Input('ipxTemplateColumnField') key: string;
    constructor(public template: TemplateRef<any>) { }
}

@Directive({
    selector: '[ipxEditTemplateColumnField]'
})
export class EditTemplateColumnFieldDirective {
    @Input('ipxEditTemplateColumnField') key: string;
    constructor(public template: TemplateRef<any>) { }
}