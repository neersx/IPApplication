import { ChangeDetectionStrategy, Component, EventEmitter, Injector, Input, OnInit, Output, TemplateRef, Type, ViewChild } from '@angular/core';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { getComponent } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { IpxKendoGridComponent } from '../ipx-kendo-grid.component';
import { ContextMenuParams, ProviderNameEnum } from './ipx-group-item-contextmenu.model';
@Component({
    selector: 'ipx-group-items',
    templateUrl: './ipx-group-items.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class GroupItemsComponent implements OnInit {

    constructor(private readonly injector: Injector) {
    }

    @Input() items: any;
    @Input() columns: any;
    @Input() detailTemplate: TemplateRef<any>;
    @Input() isShowContextMenu: boolean;
    @Input() contextMenuParams: ContextMenuParams;
    @Output() readonly groupItemClicked = new EventEmitter<any>();
    @Input() detailTemplateShowCondition: Function;
    _resultsGrid: IpxKendoGridComponent;
    gridoptions: IpxGridOptions;
    @ViewChild('resultsGridItem') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
        }
    }
    menuProvider: any;
    taskItems: any = [];

    ngOnInit(): void {
        this.gridoptions = this.buildGridOptions();
        if (this.contextMenuParams && this.contextMenuParams.providerName) {
            this.loadProviderComponent(this.contextMenuParams.providerName);
            this.menuProvider.isMaintainEventFireTaskMenuWhenGrouping$.subscribe(result => {
                if (result) {
                    if (this._resultsGrid) {
                        const data: any = this._resultsGrid.wrapper.data;
                        const rowIndex = data.findIndex(a => a.taskPlannerRowKey === result.taskPlannerRowKey);
                        this._resultsGrid.expandAll(rowIndex);
                    }
                }
            });
        }
    }

    loadProviderComponent = (providername: string): void => {
        const provider: any = getComponent(this.contextMenuParams.providerName) as Type<any>;
        this.menuProvider = this.injector.get(provider);

        switch (providername) {
            case ProviderNameEnum.SearchResultsTaskMenuProvider:
                if (this.menuProvider.initializeContext) {
                    this.menuProvider.initializeContext(this.contextMenuParams.contextParams.permissions,
                        this.contextMenuParams.contextParams.queryContextKey, this.contextMenuParams.contextParams.isHosted,
                        this.contextMenuParams.contextParams.viewData);
                }
                break;
            default:
                break;
        }
    };

    onMenuItemSelected = (menuEventDataItem: any): void => {
        menuEventDataItem.event.item.action(menuEventDataItem.dataItem, menuEventDataItem.event);
    };

    initializeTaskItems = (dataItem: any): void => {
        if (this.menuProvider) {
            this.taskItems = this.menuProvider.getConfigurationTaskMenuItems(dataItem);
            if (dataItem.caseKey) {
                const webLink = _.find(this.menuProvider._baseTasks, (t: any) => {
                    return t.menu && t.menu.id === 'caseWebLinks';
                });
                if (webLink) {
                    this.menuProvider.subscribeCaseWebLinks(dataItem, webLink);
                }
            }
        }
    };

    private buildGridOptions(): IpxGridOptions {
        const options: IpxGridOptions = {
            pageable: true,
            hideHeader: true,
            navigable: true,
            showContextMenu: this.isShowContextMenu,
            selectable: {
                mode: 'single'
            },
            detailTemplate: this.detailTemplate,
            detailTemplateShowCondition: (dataItem: any) => {
                return this.detailTemplateShowCondition(dataItem);
            },
            read$: (queryParams) => {
                if (this.items.length < queryParams.take) {
                    return of(this.items).pipe(delay(100));
                }

                const paginatedData = {
                    data: this.items.slice(queryParams.skip, queryParams.skip + queryParams.take),
                    pagination: {
                        total: this.items.length
                    }
                };

                return of(paginatedData).pipe(delay(100));
            },
            columns: this.columns
        };

        return options;
    }

    onDataItemClicked = (event: any) => {
        this.groupItemClicked.emit(event);
    };
}