import { Directive, Input, TemplateRef } from '@angular/core';

@Directive({
    selector: '[ipxEditor]'
})
export class EditorDirective {
    @Input('ipxEditor') key: string;
    constructor(public template: TemplateRef<any>) { }
}