import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { ContextMenuParams } from './ipx-group-item-contextmenu.model';

@Component({
    selector: 'ipx-group-header-item',
    templateUrl: './ipx-group.header.item.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class GroupHeaderItemComponent implements OnInit {
    @ViewChild('detailsTemplate', { static: true }) detailsTemplate: TemplateRef<any>;

    @Input() items: Array<any> = [];
    @Input() columns: Array<any> = [];
    @Input() detailTemplate: TemplateRef<any>;
    @Input() detailTemplateShowCondition: Function;
    @Input() isShowContextMenu: boolean;
    @Input() contextMenuParams: ContextMenuParams;
    @Output() readonly groupItemClicked = new EventEmitter<any>();
    gridOptions: IpxGridOptions;

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
    }

    private buildGridOptions(): IpxGridOptions {
        const options: IpxGridOptions = {
            hideHeader: true,
            selectable: {
                mode: 'single'
            },
            showContextMenu: false,
            customRowClass: (context) => {
                return ' k-grouping-row';
            },
            read$: () => of(this.items).pipe(delay(100)),
            columns: [{
                field: 'detail', title: '', template: true
            }]
        };

        options.detailTemplateShowCondition = (dataItem: any): boolean => true;
        options.detailTemplate = this.detailsTemplate;

        return options;
    }

    onGroupItemClicked = (event: any) => {
        this.groupItemClicked.emit(event);
    };
}