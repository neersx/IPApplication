import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { takeWhile } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { OfficeMaintenanceComponent } from './office-maintenance/office-maintenance.component';
import { OfficePermissions } from './offices.model';
import { OfficeService } from './offices.service';

@Component({
    selector: 'offices',
    templateUrl: './offices.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ]
})

export class OfficeComponent implements OnInit {
    @Input() viewData: OfficePermissions;
    gridOptions: IpxGridOptions;
    showSearchBar = true;
    searchText: string;
    addedRecordId: number;
    actions: Array<IpxBulkActionOptions>;
    cannotDeleteOffices: Array<string> = [];
    _resultsGrid: IpxKendoGridComponent;
    @ViewChild('officeGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }

    constructor(private readonly service: OfficeService,
        private readonly modalService: IpxModalService,
        private readonly notificationService: NotificationService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly translate: TranslateService) {
    }

    ngOnInit(): void {
        this.actions = this.initializeMenuActions();
        this.gridOptions = this.buildGridOptions();
    }

    private initializeMenuActions(): Array<IpxBulkActionOptions> {
        const menuItems: Array<IpxBulkActionOptions> = [];

        if (this.viewData.canEdit) {
            menuItems.push({
                ...new IpxBulkActionOptions(),
                id: 'edit',
                icon: 'cpa-icon cpa-icon-edit',
                text: 'office.edit',
                enabled: false,
                click: this.editOffice
            });
        }
        if (this.viewData.canDelete) {
            menuItems.push({
                ...new IpxBulkActionOptions(),
                id: 'delete',
                icon: 'cpa-icon cpa-icon-trash',
                text: 'office.delete',
                enabled: false,
                click: this.deleteOfficeConfirmation
            });
        }

        return menuItems;
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
        });
    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            sortable: true,
            reorderable: false,
            showGridMessagesUsingInlineAlert: false,
            enableGridAdd: true,
            read$: (queryParams) => {

                return this.service.getOffices({ text: this.searchText }, queryParams);
            },
            customRowClass: (context) => {
                let returnValue = '';
                if (context.dataItem && context.dataItem.key === this.addedRecordId) {
                    returnValue += ' saved k-state-selected selected';
                }

                if (context.dataItem && this.cannotDeleteOffices && this.cannotDeleteOffices.length > 0 && this.cannotDeleteOffices.indexOf(context.dataItem.key) !== -1) {
                    returnValue += ' error';
                }

                return returnValue;
            },
            selectable: this.viewData.canDelete || this.viewData.canEdit ? {
                mode: 'multiple'
            } : false,
            selectedRecords: {
                rows: {
                    rowKeyField: 'key',
                    selectedKeys: []
                }
            },
            rowMaintenance: {
                rowEditKeyField: 'key'
            },
            bulkActions: this.actions,
            columns: this.getColumns()
        };
    }

    editOffice = (resultGrid: IpxKendoGridComponent): void => {
        const selectedRowKey = resultGrid.getRowSelectionParams().rowSelection[0];
        this.onRowAddedOrEdited(selectedRowKey, 'Edit');
    };

    onRowAddedOrEdited(id: number, state: string): void {
        const modal = this.modalService.openModal(OfficeMaintenanceComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                state,
                entryId: id
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

    deleteOfficeConfirmation = (resultGrid: IpxKendoGridComponent): void => {
        const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null);
        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => {
                const rowSelectionParams = resultGrid.getRowSelectionParams();
                let allKeys = [];
                if (rowSelectionParams.isAllPageSelect) {
                    const dataRows = Array.isArray(this._resultsGrid.wrapper.data) ? this._resultsGrid.wrapper.data
                        : (this._resultsGrid.wrapper.data).data;
                    allKeys = _.pluck(dataRows, 'key');
                } else {
                    allKeys = _.map(resultGrid.getRowSelectionParams().allSelectedItems, 'key');
                }
                if (allKeys.length > 0) {
                    this.deleteOffice(allKeys);
                }
            });
    };

    deleteOffice = (allKeys: Array<number>): void => {
        this.service.deleteOffices(allKeys).subscribe((response: any) => {
            if (response.hasError) {
                const allInUse = allKeys.length === response.inUseIds.length;
                const message = allInUse ? this.translate.instant('modal.alert.alreadyInUse')
                    : this.translate.instant('modal.alert.partialComplete') + '<br/>' + this.translate.instant('modal.alert.alreadyInUse');
                const title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';
                this.notificationService.alert({ title, message });
                this.cannotDeleteOffices = response.inUseIds;
            } else {
                this.cannotDeleteOffices = null;
                this.notificationService.success();
            }
            this._resultsGrid.clearSelection();
            this.gridOptions._search();
        });
    };

    search(): void {
        this.gridOptions._search();
    }

    clear(): void {
        this.searchText = '';
        this.gridOptions._search();
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'office.column.description',
            field: 'value',
            sortable: true,
            template: true
        }, {
            title: 'office.column.organisation',
            field: 'organisation',
            sortable: true
        }, {
            title: 'office.column.country',
            field: 'country',
            sortable: true
        }, {
            title: 'office.column.language',
            field: 'defaultLanguage',
            sortable: true
        }];

        return columns;
    };
}