import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { takeWhile } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { ExchangeRateSchedulePermissions } from './exchange-rate-schedule.model';
import { ExchangeRateScheduleService } from './exchange-rate-schedule.service';
import { MaintainExchangeRateScheduleComponent } from './maintain-exchange-rate-schedule/maintain-exchange-rate-schedule.component';

@Component({
    selector: 'exchange-rate-schedule',
    templateUrl: './exchange-rate-schedule.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ]
})

export class ExchangeRateScheduleComponent implements OnInit {
    @Input() viewData: ExchangeRateSchedulePermissions;
    gridOptions: IpxGridOptions;
    showSearchBar = true;
    searchText: string;
    _resultsGrid: any;
    addedRecordId: string;
    actions: Array<IpxBulkActionOptions>;
    cannotDeleteIds: Array<string> = [];
    @ViewChild('exchangeRateScheduleGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }

    constructor(private readonly service: ExchangeRateScheduleService, readonly localSettings: LocalSettings, private readonly modalService: IpxModalService, private readonly notificationService: NotificationService,
        private readonly translate: TranslateService, private readonly ipxNotificationService: IpxNotificationService) {
    }

    ngOnInit(): void {
        this.actions = this.initializeMenuActions();
        this.gridOptions = this.buildGridOptions();
    }

    private readonly subscribeRowSelectionChange = () => {
        this._resultsGrid.rowSelectionChanged.subscribe((event) => {
            const edit = this.actions.find(x => x.id === 'edit');
            if (edit) {
                edit.enabled = event.rowSelection.length === 1;
            }
            const bulkDelete = this.actions.find(x => x.id === 'delete');
            if (bulkDelete) {
                bulkDelete.enabled = event.rowSelection.length > 0;
            }
            const exchangeRateVariation = this.actions.find(x => x.id === 'exchangeRateVariation');
            if (exchangeRateVariation) {
                exchangeRateVariation.enabled = event.rowSelection.length === 1;
            }
        });
    };

    private initializeMenuActions(): Array<IpxBulkActionOptions> {
        const menuItems: Array<IpxBulkActionOptions> = [{
            ...new IpxBulkActionOptions(),
            id: 'exchangeRateVariation',
            icon: 'cpa-icon cpa-icon-line-chart',
            text: 'exchangeRateVariation.maintenance.title',
            enabled: false,
            click: this.openExchangeRateVariation
        }];

        if (this.viewData.canEdit) {
            menuItems.push(
                {
                    ...new IpxBulkActionOptions(),
                    id: 'edit',
                    icon: 'cpa-icon cpa-icon-edit',
                    text: 'exchangeRateSchedule.maintenance.editBulk',
                    enabled: false,
                    click: this.editExchangeRateSchedule
                }
            );
        }

        if (this.viewData.canDelete) {
            menuItems.push(
                {
                    ...new IpxBulkActionOptions(),
                    id: 'delete',
                    icon: 'cpa-icon cpa-icon-trash',
                    text: 'bulkactionsmenu.delete',
                    enabled: false,
                    click: this.deleteConfirmation
                }
            );
        }

        return menuItems;
    }

    editExchangeRateSchedule = (resultGrid: IpxKendoGridComponent) => {
        const selectedRowKey = resultGrid.getRowSelectionParams().rowSelection[0];
        this.onRowAddedOrEdited(selectedRowKey, 'E');
    };

    openExchangeRateVariation = (resultGrid: IpxKendoGridComponent) => {
        const selectedRowKey = resultGrid.getRowSelectionParams().rowSelection[0];
        const exchangeRateSchedule = resultGrid.getRowSelectionParams().allSelectedItems[0].description;
        this.localSettings.keys.exchangeRateVariation.data.setSession({ exchangeRateSchedule: selectedRowKey, exchangeRateScheduleDesc: exchangeRateSchedule });
        const url = '#/configuration/exchange-rate-variation';
        window.open(url, '_blank');
    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            sortable: true,
            reorderable: false,
            pageable: {
                pageSizes: [5, 10, 20, 50],
                pageSizeSetting: this.localSettings.keys.exchangeRateSchedule.pageSize
            },
            bulkActions: this.actions,
            selectable: {
                mode: 'multiple'
            },
            selectedRecords: {
                rows: {
                    rowKeyField: 'id',
                    selectedKeys: []
                }
            },
            showGridMessagesUsingInlineAlert: false,
            read$: (queryParams) => {

                return this.service.getExchangeRateSchedule({ text: this.searchText }, queryParams);
            },
            columns: this.getColumns(),
            customRowClass: (context) => {
                let returnValue = '';
                if (context.dataItem && this.cannotDeleteIds && this.cannotDeleteIds.length > 0 && this.cannotDeleteIds.indexOf(context.dataItem.id) !== -1) {
                    returnValue += ' error';
                }

                if (context.dataItem && context.dataItem.code === this.addedRecordId) {
                    returnValue += ' saved k-state-selected selected';
                }

                return returnValue;
            }
        };
    }

    search(): void {
        this._resultsGrid.clearSelection();
        this.gridOptions._search();
    }

    clear(): void {
        this.searchText = '';
        this._resultsGrid.clearSelection();
        this.gridOptions._search();
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'exchangeRateSchedule.column.code',
            field: 'code',
            sortable: true,
            template: true
        }, {
            title: 'exchangeRateSchedule.column.description',
            field: 'description',
            sortable: true
        }];

        return columns;
    };

    onRowAddedOrEdited(data: any, state: string): void {
        const modal = this.modalService.openModal(MaintainExchangeRateScheduleComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                id: data,
                isAdding: state === rowStatus.Adding
            }
        });
        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event);
            }
        );

        modal.content.addedRecordId$.subscribe(
            (event: any) => {
                this.addedRecordId = event;
            }
        );
    }

    onCloseModal(event): void {
        if (event) {
            this.notificationService.success();
            this.gridOptions._search();
        }
    }

    deleteConfirmation = (resultGrid: IpxKendoGridComponent): void => {
        const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null);
        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => {
                const rowSelectionParams = resultGrid.getRowSelectionParams();
                let allKeys = [];
                if (rowSelectionParams.isAllPageSelect) {
                    const dataRows = Array.isArray(this._resultsGrid.wrapper.data) ? this._resultsGrid.wrapper.data
                        : (this._resultsGrid.wrapper.data).data;
                    allKeys = _.pluck(dataRows, 'id');
                } else {
                    allKeys = _.map(resultGrid.getRowSelectionParams().allSelectedItems, 'id');
                }
                if (allKeys.length > 0) {
                    this.delete(allKeys);
                }
            });
    };

    delete = (allKeys: Array<string>): void => {
        this.service.deleteExchangeRateSchedules(allKeys).subscribe((response: any) => {
            if (response.hasError) {
                const allInUse = allKeys.length === response.inUseIds.length;
                const message = allInUse ? this.translate.instant('modal.alert.alreadyInUse')
                    : this.translate.instant('modal.alert.partialComplete') + '<br/>' + this.translate.instant('modal.alert.alreadyInUse');
                const title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';
                this.notificationService.alert({ title, message });
                this.cannotDeleteIds = response.inUseIds;
            } else {
                this.cannotDeleteIds = null;
                this.notificationService.success();
            }
            this._resultsGrid.clearSelection();
            this.gridOptions._search();
        });
    };
}