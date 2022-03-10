import { ChangeDetectionStrategy, Component, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { KendoGridGroupingDemoService } from './kendo-grid-grouping-demo.service';
import { productWithFlatData } from './products';

@Component({
    selector: 'kendo-grid-grouping-demo',
    templateUrl: './kendo-grid-grouping-demo.component.html',
    providers: [KendoGridGroupingDemoService],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class KendoGridGroupingDemoComponent implements OnInit {
    @ViewChild('groupDetailTemplate', { static: true }) groupDetailTemplate: TemplateRef<any>;
    @ViewChild('kendoDetailTemplate', { static: true }) kendoDetailTemplate: TemplateRef<any>;
    @ViewChild('resultsGrid', { static: true }) resultsGrid: IpxKendoGridComponent;

    gridOptionsPlane: IpxGridOptions;
    gridDataPlane: Array<any> = productWithFlatData;
    taskItems: any = [];
    isShowContextMenu: boolean;

    anySelectedSubject = new BehaviorSubject<boolean>(false);
    anySelected$ = this.anySelectedSubject.asObservable();
    nothingSelectedSubject = new BehaviorSubject<boolean>(true);
    nothingSelected$ = this.nothingSelectedSubject.asObservable();

    ngOnInit(): void {
        this.isShowContextMenu = true;
        this.gridOptionsPlane = this.buildGridOptionsPlaneData();
    }

    constructor(private readonly service: KendoGridGroupingDemoService) {

    }

    onMenuItemSelected = (menuEventDataItem: any): void => {
        alert('menu item clicked');
    };

    initializeTaskItems = (dataItem: any): void => {
        this.taskItems = [];
        const webLink = {
            id: 'caseWebLinks',
            text: 'caseTaskMenu.openCaseWebLinks',
            icon: 'cpa-icon cpa-icon-bookmark',
            action: this.openLink,
            items: []
        };
        this.taskItems.push(webLink);
    };

    openLink = (item?: any, event?: any): void => {
        const a = 1;
    };

    actions: Array<IpxBulkActionOptions> = [{
        ...new IpxBulkActionOptions(),
        id: 'Release',
        icon: 'cpa-icon cpa-icon-play',
        text: 'policing.queue.actions.release',
        enabled$: this.anySelected$,
        click: () => {
            alert('Release clicked');
        }
    }, {
        ...new IpxBulkActionOptions(),
        id: 'Hold',
        icon: 'cpa-icon cpa-icon-pause',
        text: 'policing.queue.actions.hold',
        enabled$: this.anySelected$,
        click: () => {
            alert('Hold clicked');
        }
    }];

    private buildGridOptionsPlaneData(): IpxGridOptions {
        this.resultsGrid.rowSelectionChanged.subscribe((event) => {
            const res = event.rowSelection.length > 0;
            this.anySelectedSubject.next(res);
            this.nothingSelectedSubject.next(!res);
        });

        const options: IpxGridOptions = {
            groups: [],
            groupable: true,
            pageable: true,
            selectable: {
                mode: 'multiple'
            },
            showContextMenu: this.isShowContextMenu,
            bulkActions: this.actions,
            detailTemplate: this.kendoDetailTemplate,
            detailTemplateShowCondition: (dataItem: any) => {
                return dataItem.caseId === -703;
            },
            groupDetailTemplate: this.groupDetailTemplate,
            customRowClass: (context) => {
                let returnValue = '';
                if (options.groups.length > 0) {
                    returnValue += ' k-grouping-row';
                }

                return returnValue;
            },
            read$: (queryParams) => {
                return this.service.getPagedData$(queryParams);
            },
            columns: [{
                field: 'irn', title: 'Irn', width: 150
            }, {
                field: 'title', title: 'Title', width: 250, sortable: true
            }, {
                field: 'country', title: 'Country', width: 250, sortable: true
            }, {
                field: 'caseType', title: 'CaseType', width: 250, sortable: true
            }, {
                field: 'propertyType', title: 'PropertyType', sortable: false
            }]
        };

        return options;
    }
}