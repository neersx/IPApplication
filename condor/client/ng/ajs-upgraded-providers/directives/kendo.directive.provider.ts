import { Directive, ElementRef, EventEmitter, Injector, Input, Output } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';

export class KendoGridOptions {
    context: any;
    id: string;
    filterOptions?: any;
    pageable?: any;
    scrollable?: boolean;
    autoBind?: boolean;
    resizable?: boolean;
    reorderable?: boolean;
    navigatable?: boolean;
    selectable?: any;
    onSelect?: any;
    read: any;
    readFilterMetadata?: any;
    hideExpand?: any;
    columns: any;
    detailTemplate?: any;
    onPageSizeChanged?: any;
    onDataCreated?: any;
    onDataBound?: any;
    getCurrentFilters?: any;
    clickHyperlinkedCell?: any;
    getFiltersExcept?: any;
    expandAll?: any;
    [propName: string]: any;
}

@Directive({
    selector: 'ip-kendo-grid-upg'
})
export class KendoGridDirective extends UpgradeComponent {
    @Input() gridOptions: KendoGridOptions;
    @Input() id: string;
    @Input() showAdd?: boolean;
    @Input() addItemName?: string;
    @Input() onAddClick?: any;
    @Output() readonly gridOptionsChange: EventEmitter<KendoGridOptions>;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipKendoGridWrapper', elementRef, injector);
    }
}
