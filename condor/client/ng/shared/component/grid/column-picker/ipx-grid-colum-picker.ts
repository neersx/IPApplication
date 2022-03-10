import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, NgZone, OnDestroy, OnInit, Renderer2, ViewChild, ViewContainerRef } from '@angular/core';
import { ColumnInfoService } from '@progress/kendo-angular-grid';
import { PopupService } from '@progress/kendo-angular-popup';
import * as _ from 'underscore';
import { ColumnSelection, GridColumnDefinition } from '../ipx-grid.models';

@Component({
    selector: 'ipx-grid-column-picker',
    templateUrl: './ipx-grid-colum-picker.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxGridColumnPickerComponent implements OnInit, OnDestroy {

    @Input() columnSelection?: ColumnSelection;
    @Input() gridColumns?: Array<GridColumnDefinition>;
    @ViewChild('columnPickerContainer', { read: ViewContainerRef, static: true }) container: ViewContainerRef;

    get columns(): Array<any> {
        return this.columnInfoService.leafNamedColumns;
    }

    private popupRef: any;
    private closeClick: any;
    private originalColumns: Array<any>;

    constructor(
        private readonly columnInfoService: ColumnInfoService,
        private readonly popupService: PopupService,
        private readonly ngZone: NgZone,
        private readonly renderer: Renderer2,
        private readonly changeDetector: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.originalColumns = this.gridColumns.map((column, index) => {
            return { field: column.field, hidden: column.hidden, index };
        }).slice();
        if (this.columnSelection && this.columnSelection.localSetting) {
            const storedColumns = this.columnSelection.localSetting;
            _.map(this.columns, (c: any) => {
                _.each(storedColumns.getLocal, (s: any) => {
                    if (s.field === c.field) {
                        c.hidden = s.hidden;
                        c.orderIndex = s.index;
                    }
                });
            });
        }
    }

    ngOnDestroy(): void {
        this.close();
    }

    toggle(anchor: any, template: any): void {
        if (!this.popupRef) {
            this.popupRef = this.popupService.open({
                anchor,
                content: template,
                animate: false,
                appendTo: this.container,
                positionMode: 'absolute',
                anchorAlign: { vertical: 'bottom', horizontal: 'right' },
                popupAlign: { vertical: 'top', horizontal: 'right' }
            });

            this.renderer.setAttribute(this.popupRef.popupElement, 'dir', 'ltr');

            this.ngZone.runOutsideAngular(() =>
                this.closeClick = this.renderer.listen('document', 'click', ({ target }) => {
                    if (!this.closest(target, node => node === this.popupRef.popupElement || node === anchor)) {
                        this.close();
                    }
                })
            );
        } else {
            this.close();
        }
    }

    onReset(changed: Array<any>): void {
        this.close();
        if (changed) {
            this.changeDetector.markForCheck();
            this.columnInfoService.changeVisibility(changed);
        }
        _.map(this.columns, (c: any) => {
            _.each(this.gridColumns, (s: any, index: number) => {
                if (s.field === c.field) {
                    c.hidden = s.hidden;
                    c.orderIndex = index;
                }
            });
        });
        this.changeDetector.detectChanges();

        if (this.columnSelection) {
            this.columnSelection.localSetting.removeLocal();
        }
    }

    onChange(changed: Array<any>): void {
        this.changeDetector.markForCheck();
        this.columnInfoService.changeVisibility(changed);
        if (this.columnSelection) {
            const cols = this.columnSelection.localSetting.getLocal || this.columns.map((column, index) => {
                return { field: column.field, hidden: column.hidden, index };
            }).slice();
            _.each(changed.slice(), (column: any) => {
                const col = _.find(cols, (c: any) => {
                    return c.field === column.field;
                });
                if (col) {
                    col.hidden = column.hidden;
                }
            });
            this.columnSelection.localSetting.setLocal(cols);
        }
    }

    private close(): void {
        if (this.popupRef) {
            this.popupRef.close();
            this.popupRef = null;
        }
        this.detachClose();
    }

    private detachClose(): void {
        if (this.closeClick) {
            this.closeClick();
            this.closeClick = null;
        }
    }

    closest = (node, predicate) => {
        while (node && !predicate(node)) {
            // tslint:disable-next-line: no-parameter-reassignment
            node = node.parentNode;
        }

        return node;
    };
}