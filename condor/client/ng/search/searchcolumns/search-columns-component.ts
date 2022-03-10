import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject } from 'rxjs';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import * as _ from 'underscore';
import { SearchColumnMaintenanceComponent } from './search-column.maintenance.component';
import { FilterValue, QueryColumnViewData, SearchColumnState, SearchCriteria } from './search-columns.model';
import { SearchColumnsService } from './search-columns.service';

@Component({
    selector: 'search-columns',
    templateUrl: './search-columns-component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class SearchColumnsComponent implements OnInit {
    @Input() viewData: QueryColumnViewData;

    gridOptions: IpxGridOptions;
    searchCriteria: SearchCriteria;
    filterValue: FilterValue;
    displayFilterBy: Boolean;
    searchName: string;
    queryContextKeyEnum: queryContextKeyEnum;
    headerText: string;
    tooltipSearchInternal: string;
    tooltipSearchExternal: string;
    isInternalText: string;
    searchColumnModalRef: BsModalRef;
    searchColumnState = SearchColumnState;
    @ViewChild('searchColumnGrid', { static: true }) searchColumnGrid: IpxKendoGridComponent;

    constructor(private readonly searchColumnService: SearchColumnsService,
        private readonly translate: TranslateService, private readonly modalService: IpxModalService,
        private readonly notificationService: NotificationService) { }

    ngOnInit(): void {
        const permisions = this.viewData.queryContextPermissions;
        if (permisions.length > 1) {
            this.filterValue = {
                internalContext: permisions[0].queryContext,
                externalContext: permisions[1].queryContext,
                displayForInternal: permisions[0].displayForInternal
            };
            const internal = permisions[0].canCreateSearchColumn
                || permisions[0].canUpdateSearchColumn
                || permisions[0].canDeleteSearchColumn;
            const external = permisions[1].canCreateSearchColumn
                || permisions[1].canUpdateSearchColumn
                || permisions[1].canDeleteSearchColumn;
            this.displayFilterBy = internal && external;
            this.isInternalText = internal ? this.translate.instant('SearchColumns.internal') : this.translate.instant('SearchColumns.external');
        } else {
            this.filterValue = {
                internalContext: permisions[0].queryContext,
                displayForInternal: permisions[0].displayForInternal
            };
            this.displayFilterBy = false;
            this.isInternalText = permisions[0].queryContextType.includes('internal') ? this.translate.instant('SearchColumns.internal') : this.translate.instant('SearchColumns.external');
        }
        this.setSearchName(this.viewData.queryContextKey);
        this.headerText = this.translate.instant('SearchColumns.header').replace('{value}', this.searchName);
        this.tooltipSearchInternal = this.translate.instant('SearchColumns.tooltipSearchInternal').replace('{value}', this.searchName);
        this.tooltipSearchExternal = this.translate.instant('SearchColumns.tooltipSearchExternal').replace('{value}', this.searchName);
        this.searchCriteria = { queryContextKey: +this.viewData.queryContextKey, text: '' };
        this.gridOptions = this.buildGridOptions();
    }

    search = (): void => {
        this.searchColumnService.inUseSearchColumns = [];
        this.gridOptions._search();
    };

    clear(): void {
        this.searchCriteria.text = '';
        this.searchColumnService.inUseSearchColumns = [];
        this.gridOptions._search();
    }

    toggleFilterOption(item: number): void {
        this.searchCriteria.queryContextKey = +item;
        this.resetSelection();
        this.gridOptions._search();
    }

    private buildGridOptions(): IpxGridOptions {
        this.searchColumnGrid.rowSelectionChanged.subscribe((event) => {
            const anySelected = event.rowSelection.length > 0;
            this.anySelectedSubject.next(anySelected);
        });

        return {
            sortable: true,
            selectable: {
                mode: 'multiple'
            },
            onDataBound: (data: any) => {
                this.searchColumnGrid.resetSelection();
                this.searchColumnService.persistSavedSearchColumns(data);
                this.searchColumnService.markInUseSearchColumns(data);
            },
            customRowClass: (context) => {
                if (context.dataItem.persisted) {
                    return ' saved';
                }
                if (context.dataItem.inUse) {
                    return ' error';
                }

                return '';
            },
            read$: (queryParams) => this.searchColumnService.getSearchColumns(this.searchCriteria, queryParams),
            columns: [{
                field: 'displayName', title: 'SearchColumns.displayName', width: 250, template: true
            }, {
                field: 'columnNameDescription', title: 'SearchColumns.columnNameDescription', template: true
            }],
            bulkActions: this.actions,
            selectedRecords: { rows: { rowKeyField: 'columnId', selectedKeys: [] } }
        };
    }

    anySelectedSubject = new BehaviorSubject<boolean>(false);
    anySelected$ = this.anySelectedSubject.asObservable();
    actions: Array<IpxBulkActionOptions> = [{
        ...new IpxBulkActionOptions(),
        id: 'Delete',
        icon: 'cpa-icon cpa-icon-trash',
        text: 'SearchColumns.bulkActions.delete',
        enabled$: this.anySelected$,
        click: () => {
            this.notificationService.confirmDelete({
                message: 'modal.confirmDelete.message'
            }).then(() => {
                this.deleteSelectedColumns();
            });
        }
    }];

    resetSelection = () => {
        this.searchColumnGrid.resetSelection();
    };

    deleteSelectedColumns = () => {
        const selections = this.searchColumnGrid.getSelectedItems('columnId');
        this.searchColumnService.deleteSearchColumns(selections, this.getCurrentContext()).subscribe((response: any) => {
            this.resetSelection();
            if (response.hasError) {
                const allInUse = selections.length === response.inUseIds.length;
                const message = allInUse ? this.translate.instant('SearchColumns.alert.alreadyInUse') + '<br/>' + this.translate.instant('SearchColumns.alert.removeFromSearch')
                    : this.translate.instant('modal.alert.partialComplete') + '<br/>' + this.translate.instant('SearchColumns.alert.alreadyInUse') + '<br/>' + this.translate.instant('SearchColumns.alert.removeFromSearch');
                const title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';

                this.searchColumnService.inUseSearchColumns = this.searchColumnService.inUseSearchColumns
                    .concat(response.inUseIds);

                this.notificationService.alert({
                    title,
                    message
                });
                this.gridOptions._search();
            } else {
                this.notificationService.success();
                this.gridOptions._search();
            }
        });
    };

    getCurrentContext = () => {
        const permissions = this.viewData.queryContextPermissions;
        let queryContextKey: Number;
        if (permissions.length > 1) {
            queryContextKey = this.filterValue.displayForInternal ? this.filterValue.internalContext
                : this.filterValue.externalContext;
        } else {
            queryContextKey = this.viewData.queryContextKey;
        }

        return queryContextKey;
    };

    openModal = (columnId: number, state: string) => {
        const queryContextKey = this.getCurrentContext();
        const initialState = {
            columnId,
            queryContextKey,
            states: state,
            appliesToInternal: this.filterValue.displayForInternal,
            displayFilterBy: this.displayFilterBy,
            displayNavigation: state === 'updating' ? true : false
        };
        const modalClass = state === this.searchColumnState.Updating ? 'modal-xl' : 'modal-lg';
        this.searchColumnModalRef = this.modalService.openModal(SearchColumnMaintenanceComponent, {
            animated: false,
            backdrop: 'static',
            class: modalClass,
            initialState
        });
        this.searchColumnModalRef.content.searchColumnRecord.subscribe(
            (callbackParams: any) => {
                this.searchColumnModalRef.hide();
                if (callbackParams.runSearch) {
                    this.gridOptions._search();
                }
            }
        );
    };

    setSearchName(queryContextKey: Number): void {
        switch (+ queryContextKey) {
            case queryContextKeyEnum.caseSearch:
            case queryContextKeyEnum.caseSearchExternal:
                this.searchName = this.translate.instant('SearchColumns.case');
                break;
            case queryContextKeyEnum.nameSearch:
            case queryContextKeyEnum.nameSearchExternal:
                this.searchName = this.translate.instant('SearchColumns.name');
                break;
            case queryContextKeyEnum.wipOverview:
                this.searchName = this.translate.instant('SearchColumns.wipOverview');
                break;
            case queryContextKeyEnum.priorArtSearch:
                this.searchName = this.translate.instant('SearchColumns.priorArt');
                break;
            case queryContextKeyEnum.caseFeeSearchInternal:
            case queryContextKeyEnum.caseFeeSearchExternal:
                this.searchName = this.translate.instant('SearchColumns.caseFeeSearchInternalExternal');
                break;
            case queryContextKeyEnum.caseInstructionSearchInternal:
            case queryContextKeyEnum.caseInstructionSearchExternal:
                this.searchName = this.translate.instant('SearchColumns.caseInstructionSearchInternalExternal');
                break;
            case queryContextKeyEnum.reciprocitySearch:
                this.searchName = this.translate.instant('SearchColumns.reciprocitySearch');
                break;
            case queryContextKeyEnum.adHocDateSearch:
                this.searchName = this.translate.instant('SearchColumns.adHocDateSearch');
                break;
            case queryContextKeyEnum.clientRequestSearchInternal:
            case queryContextKeyEnum.clientRequestSearchExternal:
                this.searchName = this.translate.instant('SearchColumns.clientRequestSearchInternalExternal');
                break;
            case queryContextKeyEnum.staffRemindersSearchColumns:
                this.searchName = this.translate.instant('SearchColumns.staffRemindersSearchColumns');
                break;
            case queryContextKeyEnum.toDoSearchColumns:
                this.searchName = this.translate.instant('SearchColumns.toDoSearchColumns');
                break;
            case queryContextKeyEnum.whatsDueSearchColumns:
                this.searchName = this.translate.instant('SearchColumns.whatsDueSearchColumns');
                break;
            case queryContextKeyEnum.workHistorySearchColumns:
                this.searchName = this.translate.instant('SearchColumns.workHistorySearchColumns');
                break;
            case queryContextKeyEnum.activitySearchColumns:
                this.searchName = this.translate.instant('SearchColumns.activitySearchColumns');
                break;
            case queryContextKeyEnum.taskPlannerSearch:
                this.searchName = this.translate.instant('SearchColumns.taskPlannerSearch');
                break;
            case queryContextKeyEnum.billSearch:
                this.searchName = this.translate.instant('SearchColumns.billSearch.title');
                break;

            default:
                break;
        }
    }
}
