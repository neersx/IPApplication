import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, Renderer2, TemplateRef, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { BehaviorSubject, of } from 'rxjs';
import { delay, distinctUntilChanged } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { DragDropBaseComponent } from 'shared/directives/drag-drop-base.component';
import * as _ from 'underscore';

@Component({
    selector: 'kendo-grid-edit-dragdrop-demo',
    templateUrl: './kendo-grid-edit-dragdrop-demo.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class KendoGridEditDragDropDemoComponent extends DragDropBaseComponent implements OnInit {
    @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
    droppedItem: any;
    getSelectedColumnsOnly = false;
    changedFormGroup: any;
    selectedColumns = Array<any>();
    availableColumnsMultipleSelelction: Array<any> = [];
    selectedColumnsMultipleSelelction = Array<any>();
    isSelectedColumnAttributeChanged = false;
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
    gridOptions: IpxGridOptions;
    constructor(private readonly fb: FormBuilder, private readonly cdr: ChangeDetectorRef, public renderer: Renderer2) {
        super(renderer);
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptionsPlaneData();
    }

    private readonly buildGridOptionsPlaneData = (): IpxGridOptions => {
        const options: IpxGridOptions = {
            sortable: false,
            showGridMessagesUsingInlineAlert: false,
            autobind: true,
            reorderable: false,
            pageable: false,
            enableGridAdd: true,
            selectable: {
                mode: 'single'
            },
            draggable: true,
            gridMessages: {
                noResultsFound: 'grid.messages.noItems',
                performSearch: ''
            },
            read$: () => {
                if (this.dragControl) {
                    return of(this.selectedColumns).pipe(delay(100));
                }

                const data = [{
                    id: 1, code: '1234/a', desc: 'Description 1'
                },
                {
                    id: 2, code: '1234/b', desc: 'Description 2'
                },
                {
                    id: 3, code: '1234/c', desc: 'Description 3'
                },
                {
                    id: 4, code: '1234/d', desc: 'Description 4'
                },
                {
                    id: 5, code: 'Case1', desc: 'Description 5'
                },
                {
                    id: 6, code: 'Case2', desc: 'Description 6'
                }];

                this.selectedColumns = data;

                return of(data).pipe(delay(100));
            },
            columns: this.getColumns(),
            canAdd: true,
            rowMaintenance: {
                rowEditKeyField: 'id'
            },
            // tslint:disable-next-line: unnecessary-bind
            createFormGroup: this.createFormGroup.bind(this)
        };

        return options;
    };

    createFormGroup = (): FormGroup => {
        const formGroup = this.fb.group({
            id: new FormControl(this.selectedColumns ? this.selectedColumns.length : 1),
            code: new FormControl(null),
            desc: new FormControl(null)
        });

        formGroup.valueChanges.pipe(distinctUntilChanged()).subscribe(value => {
            if (value) {
                this.updateSelectedColumns(value);
            }
        });

        this.changedFormGroup = formGroup;

        return formGroup;
    };

    private readonly updateSelectedColumns = (value: any): void => {
        const updatedValue = _.find(this.selectedColumns, (col => {
            return col.id === value.id;
        }));
        updatedValue.code = value.code;
        updatedValue.desc = value.desc;
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            field: 'id', title: 'ID', width: 100, template: true, hidden: true
        }, {
            field: 'code', title: 'Code', width: 200, template: true
        }, {
            field: 'desc', title: 'Description', width: 200, template: true
        }];

        return columns;
    };

    onRowAddedOrEdited = (data: any): void => {
        this.createFormGroup();
        const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: { ...this.changedFormGroup } } as any;
        this.gridOptions.maintainFormGroup$.next(rowObject);
    };

    dropItemFromKendoGridToKendoGrid(droppedItem: any): void {
        this.selectedColumns = _.without(this.selectedColumns, _.findWhere(this.selectedColumns, { id: droppedItem.id }));
        this.selectedColumns.splice(this.dropIndex, 0, droppedItem);
        this.selectedColumnsMultipleSelelction = [];
        this.selectedColumnsMultipleSelelction.push(droppedItem);
    }

    onDrop(e, dropZone): void {
        e.preventDefault();
        this.getSelectedColumnsOnly = false;
        const data = e.dataTransfer.getData('text');
        if (data) {
            this.droppedItem = JSON.parse(data);
        }

        if (dropZone === 'kendoGrid') {
            if (this.dragControl === 'kendoGrid') {
                this.dropItemFromKendoGridToKendoGrid(this.droppedItem);
            }
        }
        this.grid.closeEditedRows(0);
        this.gridOptions._search();
        this.setDragableAttributeForKendoGrid(this.selectedColumns);
        this.isSelectedColumnAttributeChanged = true;
    }
}