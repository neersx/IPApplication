import { AfterContentInit, ChangeDetectionStrategy, Component, ContentChildren, QueryList, TemplateRef } from '@angular/core';
import { TemplateTabKeyDirective } from './tabs-key.directive';

@Component({
    selector: 'ipx-tabs',
    templateUrl: './tabs.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxTabsComponent implements AfterContentInit {

    @ContentChildren(TemplateTabKeyDirective) tabTemplates: QueryList<TemplateTabKeyDirective>;
    tabs: Array<TemplateTabKeyDirective>;
    selectedTemplate: TemplateRef<any>;
    activeId: string;

    ngAfterContentInit(): void {
        this.tabs = this.tabTemplates.toArray();
        if (this.tabs.length > 0) {
            this.selectionChanged(this.tabs[0]);
        }
    }

    selectionChanged = (t: TemplateTabKeyDirective) => {
        this.selectedTemplate = t.template;
        this.activeId = t.key;
    };

    byKey = (index: number, item: TemplateTabKeyDirective): string => item.key;
}