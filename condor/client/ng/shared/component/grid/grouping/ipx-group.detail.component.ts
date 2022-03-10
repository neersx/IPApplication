import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output, TemplateRef } from '@angular/core';
import * as _ from 'underscore';
import { ContextMenuParams } from './ipx-group-item-contextmenu.model';

@Component({
    selector: 'ipx-group-detail',
    templateUrl: './ipx-group.detail.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class GroupDetailComponent implements OnInit {
    @Input() items: Array<any> = [];
    @Input() columns: Array<any> = [];
    @Input() detailTemplate: TemplateRef<any>;
    @Input() detailTemplateShowCondition: Function;
    @Input() contextMenuParams: ContextMenuParams;
    @Input() isShowContextMenu: boolean;
    @Output() readonly groupItemClicked = new EventEmitter<any>();
    hasChildren: Boolean = false;

    ngOnInit(): void {
        this.hasChildren = this.items && _.any(this.items) && _.any(this.items, (item) => {
            return item.items;
        });
    }

    onGroupItemClicked = (event: any) => {
        this.groupItemClicked.emit(event);
    };
}