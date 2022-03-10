import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { MaintainExchangerateVarComponent } from 'configuration/exchange-rate-variations/maintain-exchangerate-var/maintain-exchangerate-var.component';
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
import { CurrencyPermissions } from './currencies.model';
import { CurrenciesService } from './currencies.service';
import { ExchangeRateHistoryComponent } from './exchange-rate-history/exchange-rate-history.component';
import { MaintainCurrenciesComponent } from './maintain-currencies/maintain-currencies.component';

@Component({
    selector: 'currencies',
    templateUrl: './currencies.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ]
})

export class CurrenciesComponent implements OnInit {
    @Input() viewData: CurrencyPermissions;
    gridOptions: IpxGridOptions;
    showSearchBar = true;
    searchText: string;
    addedRecordId: number;
    actions: Array<IpxBulkActionOptions>;
    _resultsGrid: any;
    cannotDeleteCurrencies: Array<string> = [];
    @ViewChild('currenciesGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }

    constructor(private readonly service: CurrenciesService,
        readonly localSettings: LocalSettings,
        private readonly modalService: IpxModalService,
        private readonly translate: TranslateService,
        private readonly notificationService: NotificationService,
        private readonly ipxNotificationService: IpxNotificationService) {
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
                    text: 'currencies.maintenance.edit',
                    enabled: false,
                    click: this.editCurrency
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
                    click: this.deleteCurrenciesConfirmation
                }
            );
        }

        return menuItems;
    }

    openExchangeRateVariation = (resultGrid: IpxKendoGridComponent) => {
        const selectedRowKey = resultGrid.getRowSelectionParams().rowSelection[0];
        const selectedDesc = resultGrid.getRowSelectionParams().allSelectedItems[0].currencyDescription;
        this.localSettings.keys.exchangeRateVariation.data.setSession({ currency: selectedRowKey, currencyDesc: selectedDesc });
        const url = '#/configuration/exchange-rate-variation';
        window.open(url, '_blank');
    };

    editCurrency = (resultGrid: IpxKendoGridComponent) => {
        const selectedRowKey = resultGrid.getRowSelectionParams().rowSelection[0];
        this.onRowAddedOrEdited(selectedRowKey, 'E');
    };

    onRowAddedOrEdited(data: any, state: string): void {
        const modal = this.modalService.openModal(MaintainCurrenciesComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
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

    deleteCurrenciesConfirmation = (resultGrid: IpxKendoGridComponent): void => {
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
                    this.deleteCurrencies(allKeys);
                }
            });
    };

    deleteCurrencies = (allKeys: Array<string>): void => {
        this.service.deleteCurrencies(allKeys).subscribe((response: any) => {
            if (response.hasError) {
                const allInUse = allKeys.length === response.inUseIds.length;
                const message = allInUse ? this.translate.instant('modal.alert.alreadyInUse')
                    : this.translate.instant('modal.alert.partialComplete') + '<br/>' + this.translate.instant('modal.alert.alreadyInUse');
                const title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';
                this.notificationService.alert({ title, message });
                this.cannotDeleteCurrencies = response.inUseIds;
            } else {
                this.cannotDeleteCurrencies = null;
                this.notificationService.success();
            }
            this._resultsGrid.clearSelection();
            this.gridOptions._search();
        });
    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            sortable: true,
            reorderable: false,
            pageable: {
                pageSizes: [5, 10, 20, 50],
                pageSizeSetting: this.localSettings.keys.currencies.pageSize
            },
            bulkActions: (this.viewData.canEdit || this.viewData.canDelete) ? this.actions : null,
            rowMaintenance: {
                rowEditKeyField: 'id'
            },
            selectable: (this.viewData.canEdit || this.viewData.canDelete) ? {
                mode: 'multiple'
            } : false,
            selectedRecords: {
                rows: {
                    rowKeyField: 'id',
                    selectedKeys: []
                }
            },
            showGridMessagesUsingInlineAlert: false,
            read$: (queryParams) => {

                return this.service.getCurrencies({ text: this.searchText }, queryParams);
            },
            customRowClass: (context) => {
                let returnValue = '';
                if (context.dataItem && this.cannotDeleteCurrencies && this.cannotDeleteCurrencies.length > 0 && this.cannotDeleteCurrencies.indexOf(context.dataItem.id) !== -1) {
                    returnValue += ' error';
                }

                if (context.dataItem && context.dataItem.id === this.addedRecordId) {
                    returnValue += ' saved k-state-selected selected';
                }

                return returnValue;
            },
            enableGridAdd: this.viewData.canAdd,
            columns: this.getColumns()
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

    onCloseModal(event): void {
        if (event) {
            this.notificationService.success();
            this.gridOptions._search();
        }
    }

    openHistory = (dataItem: any): void => {
        this.modalService.openModal(ExchangeRateHistoryComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                currencyId: dataItem.id
            }
        });
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: '',
            field: 'hasHistory',
            template: true,
            width: 50,
            sortable: false
        },
        {
            title: 'currencies.column.code',
            field: 'currencyCode',
            sortable: true,
            template: true
        }, {
            title: 'currencies.column.description',
            field: 'currencyDescription',
            sortable: true
        }, {
            title: 'currencies.history.columns.bankRate',
            field: 'bankRate',
            sortable: true
        }, {
            title: 'currencies.history.columns.effectiveDate',
            field: 'effectiveDate',
            sortable: true,
            template: true
        }, {
            title: 'currencies.history.columns.buyFactor',
            field: 'buyFactor',
            sortable: true
        }, {
            title: 'currencies.history.columns.buyRate',
            field: 'buyRate',
            sortable: true
        }, {
            title: 'currencies.history.columns.sellFactor',
            field: 'sellFactor',
            sortable: true
        }, {
            title: 'currencies.history.columns.sellRate',
            field: 'sellRate',
            sortable: true
        }];

        return columns;
    };
}