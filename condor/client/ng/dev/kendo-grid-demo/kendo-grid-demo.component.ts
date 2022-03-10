import { ChangeDetectionStrategy, Component, ElementRef, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { CompositeFilterDescriptor, distinct } from '@progress/kendo-data-query';
import { KendoGridOptions } from 'ajs-upgraded-providers/directives/kendo.directive.provider';
import { BehaviorSubject } from 'rxjs';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { MenuDataItemEventData } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { KendoGridDemoService } from './kendo-grid-demo.service';
@Component({
    selector: 'kendo-grid-demo',
    templateUrl: './kendo-grid-demo.component.html',
    providers: [KendoGridDemoService],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class KendoGridDemoComponent implements OnInit {
    @ViewChild('lastCol', { static: true }) lastCol: TemplateRef<any>;
    @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
    @ViewChild('queueGrid', { static: true }) queueGrid: IpxKendoGridComponent;

    gridDataDefault: Array<any> =
        [
            {
                ProductID: 1,
                ProductName: 'Chai',
                SupplierID: 1,
                CategoryID: 1,
                QuantityPerUnit: '10 boxes x 20 bags',
                UnitPrice: 18,
                UnitsInStock: 39,
                UnitsOnOrder: 0,
                ReorderLevel: 10,
                Discontinued: false,
                Category: {
                    CategoryID: 1,
                    CategoryName: 'Beverages',
                    Description: 'Soft drinks, coffees, teas, beers, and ales'
                },
                FirstOrderedOn: new Date(1996, 8, 20)
            },
            {
                ProductID: 2,
                ProductName: 'Chang',
                SupplierID: 1,
                CategoryID: 1,
                QuantityPerUnit: '24 - 12 oz bottles',
                UnitPrice: 19,
                UnitsInStock: 17,
                UnitsOnOrder: 40,
                ReorderLevel: 25,
                Discontinued: false,
                Category: {
                    CategoryID: 1,
                    CategoryName: 'Beverages',
                    Description: 'Soft drinks, coffees, teas, beers, and ales'
                },
                FirstOrderedOn: new Date(1996, 7, 12)
            },
            {
                ProductID: 3,
                ProductName: 'Aniseed Syrup',
                SupplierID: 1,
                CategoryID: 2,
                QuantityPerUnit: '12 - 550 ml bottles',
                UnitPrice: 10,
                UnitsInStock: 13,
                UnitsOnOrder: 70,
                ReorderLevel: 25,
                Discontinued: false,
                Category: {
                    CategoryID: 2,
                    CategoryName: 'Condiments',
                    Description: 'Sweet and savory sauces, relishes, spreads, and seasonings'
                },
                FirstOrderedOn: new Date(1996, 8, 26)
            }];
    gridOptionsUpg: KendoGridOptions = {
        context: this,
        id: 'test',
        scrollable: false,
        autoBind: true,
        resizable: false,
        reorderable: true,
        navigatable: true,
        selectable: true,
        pageable: false,
        read: () => this.service.defaultDataPromise().then(data => {
            return data.data;
        }),
        hideExpand: true,
        columns: [{
            title: 'picklist.case.Type',
            field: 'id',
            sortable: true,
            width: '150px'
        }, {
            title: 'picklist.case.CaseRef',
            field: 'name',
            sortable: true
        }, {
            title: 'picklist.case.Title',
            field: 'type',
            sortable: true,
            width: '250px'
        }]
    };
    gridData: Array<any>;
    gridoptions: IpxGridOptions;
    gridoptionsPaged: IpxGridOptions;
    gridoptionsPolicingQueue: IpxGridOptions;
    gridoptionsOnClickSearch: IpxGridOptions;
    filter: CompositeFilterDescriptor;
    selectedRecord: any;
    taskItems: Array<any> = [];

    constructor(private readonly service: KendoGridDemoService) {

    }

    ngOnInit(): void {
        this.gridoptions = this.buildGridOptions();
        this.gridoptionsPaged = this.buildGridOptionsPaged();
        this.gridoptionsPolicingQueue = this.buildGridOptionsPolicingQueue();
        this.gridoptionsOnClickSearch = this.buildGridOptionsOnClickSearch();
        this.service.defaultDataPromise().then((data) => {
            this.gridData = data.data;
        });
        this.taskItems.push(...[{ text: 'Up', action: this.up, icon: 'cpa-icon-chevron-up' }, { text: 'Down', action: this.down, icon: 'cpa-icon-chevron-down' }]);
    }

    up = (dataItem: any): void => {
        alert(`up called for row with id: ${dataItem.id}`);
    };

    down = (dataItem: any): void => {
        alert(`down called for row with id: ${dataItem.id}`);
    };

    distinctPrimitive(fieldName: string): any {
        const ar = distinct(this.gridData, fieldName).map(item => item[fieldName]);

        return ar;
    }

    typeStyles(type: string): {
        [key: string]: string;
    } {
        return {
            'font-weight': type === 'Group' ? 'bold' : null
        };
    }

    showAlert(type: string): void {
        alert(type);
    }

    rowSelection(data): void {
        this.selectedRecord = data;
    }

    private buildGridOptions(): IpxGridOptions {
        return {
            sortable: true,
            columnPicker: true,
            filterable: true,
            selectable: {
                mode: 'single'
            },
            showContextMenu: true,
            read$: (queryParams) => this.service.getData$(queryParams),
            detailTemplate: this.detailTemplate,
            detailTemplateShowCondition: (dataItem: any): boolean => {
                return dataItem.type === 'Group';
            },
            columns: [{
                field: 'id', title: 'picklist.case.Type', width: 150, filter: 'text'
            }, {
                field: 'name', title: 'picklist.case.CaseRef', width: 250, sortable: true, template: true, filter: true
            }, {
                field: 'type', title: 'picklist.case.Title', sortable: false, width: 300, template: this.lastCol
            }, { field: 'isPosted', title: '', template: true, width: 32, sortable: false }]
        };
    }

    private buildGridOptionsOnClickSearch(): IpxGridOptions {
        return {
            autobind: false,
            read$: (queryParams) => this.service.getData$(queryParams),
            columns: [{
                field: 'id', title: 'picklist.case.Type', width: 150, filter: 'text'
            }, {
                field: 'name', title: 'picklist.case.CaseRef', width: 250, sortable: true, template: true, filter: true
            }, {
                field: 'type', title: 'picklist.case.Title', sortable: false, width: 300, template: this.lastCol
            }]
        };
    }

    private buildGridOptionsPaged(): IpxGridOptions {
        return {
            sortable: true,
            pageable: true,
            groups: [],
            selectable: {
                mode: 'single'
            },
            selectedRecords: {
                rows: {
                    rowKeyField: 'id',
                    selectedKeys: [30, 68, 15]
                }
            },
            read$: (queryParams) => this.service.getPagedData$(queryParams),
            columns: [{
                field: 'id', title: 'Id', width: 150, filter: 'text'
            }, {
                field: 'name', title: 'Name', width: 250, sortable: true, filter: true
            }, {
                field: 'components', title: 'Components', sortable: false
            }]
        };
    }

    anySelectedSubject = new BehaviorSubject<boolean>(false);
    anySelected$ = this.anySelectedSubject.asObservable();

    nothingSelectedSubject = new BehaviorSubject<boolean>(true);
    nothingSelected$ = this.nothingSelectedSubject.asObservable();

    private readonly getSelectedCount = (): number => {
        return this.queueGrid.getRowSelectionParams().rowSelection.length;
    };

    actions: Array<IpxBulkActionOptions> = [{
        ...new IpxBulkActionOptions(),
        id: 'Release',
        icon: 'cpa-icon cpa-icon-play',
        text: 'policing.queue.actions.release',
        enabled$: this.anySelected$,
        click: () => {
            alert('Release clicked for ----' + this.getSelectedCount() + ' items');
        }
    }, {
        ...new IpxBulkActionOptions(),
        id: 'Hold',
        icon: 'cpa-icon cpa-icon-pause',
        text: 'policing.queue.actions.hold',
        enabled$: this.anySelected$,
        click: () => {
            alert('Hold clicked for ----' + this.getSelectedCount() + ' items');
        }
    }, {
        ...new IpxBulkActionOptions(),
        id: 'Delete',
        icon: 'cpa-icon cpa-icon-trash',
        text: 'policing.queue.actions.delete',
        enabled$: this.anySelected$,
        click: () => {
            alert('Delete clicked for ----' + this.getSelectedCount() + ' items');
        }
    }, {
        ...new IpxBulkActionOptions(),
        id: 'ReleaseAll',
        icon: 'cpa-icon cpa-icon-play',
        text: 'policing.queue.actions.releaseAll',
        enabled$: this.nothingSelected$,
        click: () => {
            alert('ReleaseAll clicked for ----' + this.getSelectedCount() + ' items');
        }
    }, {
        ...new IpxBulkActionOptions(),
        id: 'HoldAll',
        icon: 'cpa-icon cpa-icon-pause',
        text: 'policing.queue.actions.holdAll',
        enabled$: this.nothingSelected$,
        click: () => {
            alert('HoldAll clicked for ----' + this.getSelectedCount() + ' items');
        }
    }, {
        ...new IpxBulkActionOptions(),
        id: 'DeleteAll',
        icon: 'cpa-icon cpa-icon-trash',
        text: 'policing.queue.actions.deleteAll',
        enabled$: this.nothingSelected$,
        click: () => {
            alert('DeleteAll clicked for ----' + this.getSelectedCount() + ' items');
        }
    }, {
        ...new IpxBulkActionOptions(),
        id: 'EditNextRunTime',
        icon: 'cpa-icon cpa-icon-pencil-square-o',
        text: 'policing.queue.actions.scheduleNextRunTime',
        enabled$: this.anySelected$,
        click: () => {
            alert('EditNextRunTime clicked for ----' + this.getSelectedCount() + ' items');
        }
    }];

    private buildGridOptionsPolicingQueue(): IpxGridOptions {
        this.queueGrid.rowSelectionChanged.subscribe((event) => {
            const res = event.rowSelection.length > 0;
            this.anySelectedSubject.next(res);
            this.nothingSelectedSubject.next(!res);
        });

        return {
            sortable: true,
            pageable: true,
            filterable: true,
            groupable: true,
            reorderable: true,
            selectable: {
                mode: 'multiple'
            },
            read$: (queryParams) => this.service.getPolicingQueue$(queryParams),
            filterMetaData$: (column, otherFilters) => this.service.getColumnFilterData$(column, null, otherFilters),
            columns: [{
                field: 'requestId', title: 'requestId', width: 150, fixed: true
            }, {
                field: 'caseReference', title: 'caseReference', sortable: false, filter: true
            }, {
                field: 'typeOfRequest', title: 'typeOfRequest', width: 250, sortable: true, filter: true
            }],
            customRowClass: (context) => context.index % 2 === 0 ? 'saved' : '',
            bulkActions: this.actions,
            selectedRecords: { rows: { rowKeyField: 'requestId', selectedKeys: [] } }
        };
    }

    onMenuItemSelected = (menuEventDataItem: MenuDataItemEventData): void => {
        menuEventDataItem.event.item.action(menuEventDataItem.dataItem);
    };
}
