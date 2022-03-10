import { ChangeDetectionStrategy, Component, QueryList, TemplateRef, ViewChildren } from '@angular/core';

@Component({
    selector: 'ipx-tooltip-templates',
    templateUrl: './tooltip-templates.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class TooltipTemplatesComponent {
    @ViewChildren(TemplateRef) templates: QueryList<TemplateRef<any>>;
}