import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnDestroy, OnInit, Output, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BehaviorSubject, Subscription } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { ValidationError } from 'shared/component/forms/validation-error';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { CaseDetailService } from '../case-detail.service';
import { FileLocationsMaintenanceComponent } from './file-locations-maintenance/file-locations-maintenance.component';
import { FileLocationPermissions } from './file-locations.component';
import { FileLocationsService } from './file-locations.service';

@Component({
    selector: 'file-locations-grid',
    templateUrl: './file-locations-grid.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class FileLocationsGridComponent implements OnInit, OnDestroy {
    gridOptions: IpxGridOptions;
    dateformat: any;
    @Input() topic: Topic;
    @Input() showHistory = false;
    @Input() isHosted: boolean;
    @Input() fileHistoryFromMaintenance: boolean;
    @Input() filePartId: number;
    getColumnFilterData: Array<any>;
    rowEditUpdates: { [rowKey: string]: any };
    @Input() permissions: FileLocationPermissions;
    @Output() readonly pageChanged = new EventEmitter();
    @Output() readonly gridChanged = new EventEmitter();
    @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
    skip = 0;
    subscription: Subscription;
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);

    constructor(readonly localSettings: LocalSettings,
        readonly service: FileLocationsService,
        private readonly modalService: IpxModalService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly caseDetailService: CaseDetailService,
        private readonly notificationService: NotificationService,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService) { }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.subscription = this.caseDetailService.resetChanges$.subscribe((val: boolean) => {
            if (val) {
                this.resetForms();
            }
        });
        this.caseDetailService.errorDetails$.subscribe(errs => {
            this.setErrors(errs);
        });
        this.handleShortcuts();
    }

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.ADD, (): void => { if (this.isHosted) { this.grid.onAdd(); } }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.ADD])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    setErrors = (errors: Array<ValidationError>): void => {
        if (errors) {
            errors.map((errs) => {
                const fg = this.grid.rowEditFormGroups[errs.id];
                if (fg) {
                    this.setDataRowErrors(true, errs.id);
                    this.notificationService.alert({ message: 'field.errors.duplicateDesignElement', continue: 'Ok' });
                    this.refreshStatus();
                }
            });
        }
    };

    private resetForms(): void {
        if (this.grid) {
            this.grid.closeEditedRows(this.skip);
            this.rowEditUpdates = {};
            this.grid.rowEditFormGroups = null;
            this.grid.search();
        }
    }

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            pageable: this.showHistory ? {
                pageSizes: [5, 10, 20, 50],
                pageSizeSetting: this.localSettings.keys.caseView.fileLocations.pageSize
            } : false,
            reorderable: this.isHosted ? false : true,
            sortable: this.fileHistoryFromMaintenance ? false : true,
            filterable: this.fileHistoryFromMaintenance ? false : true,
            enableGridAdd: (this.isHosted && this.permissions.CAN_CREATE_CASE) ? true : false,
            canAdd: (this.permissions.CAN_MAINTAIN && !this.showHistory && !this.fileHistoryFromMaintenance) ? this.permissions.CAN_CREATE_CASE : null,
            rowMaintenance: (this.permissions.CAN_MAINTAIN && !this.showHistory && !this.fileHistoryFromMaintenance) ? {
                canEdit: this.permissions.CAN_UPDATE,
                canDelete: this.permissions.CAN_DELETE,
                rowEditKeyField: 'id'
            } : null,
            maintainFormGroup$: this.maintainFormGroup$,
            read$: (queryParams) => {
                if (this.fileHistoryFromMaintenance) {
                    return this.service.getFileLocationForFilePart(this.topic.params.viewData.caseKey, queryParams, this.filePartId);
                }

                return this.service.getFileLocations(this.topic.params.viewData.caseKey, queryParams, this.showHistory);
            },
            filterMetaData$: (column, otherFilters) => this.service.getColumnFilterData$(column, this.topic.params.viewData.caseKey, otherFilters),
            onDataBound: (data: any) => {
                if (data && data.total && this.topic.setCount) {
                    this.topic.setCount.emit(data.total);
                }
            },
            columns: this.getColumns()
        };
    }

    onRowAddedOrEdited = (data: any): void => {
        const modal = this.modalService.openModal(FileLocationsMaintenanceComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                dataItem: data.dataItem,
                isAdding: data.dataItem.status === rowStatus.Adding,
                grid: this.grid,
                topic: this.topic,
                permissions: this.permissions,
                rowIndex: data.rowIndex
            }
        });
        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event, data);
            }
        );
    };

    onCloseModal(event, data): void {
        if (event.success) {
            const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: event.formGroup } as any;
            this.gridOptions.maintainFormGroup$.next(rowObject);
            this.updateChangeStatus();
        }
        if (this.isAnyRecordAddedWithPaging() && !this.service.isAddAnotherChecked.getValue()) {
            this.grid.closeEditedRows(this.skip);
            this.gridOptions._selectPage(1);
            this.updateChangeStatus();
        }
        if (event.success) {
            if (this.service.isAddAnotherChecked.getValue()) {
                this.grid.addRow();
            } else if (this.modalService.modalRef) {
                this.modalService.modalRef.hide();
            }
        }
    }
    getDataRows = (): Array<any> => {
        return Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
    };

    onPageChanged(): void {
        this.grid.closeEditedRows(this.skip);
        this.pageChanged.emit();
        this.skip = this.grid.wrapper.skip;
    }

    updateChangeStatus = (): void => {
        this.grid.checkChanges();
        const dataRows = this.getDataRows();
        this.topic.hasChanges = dataRows.some((r) => r.status);
        this.service.raisePendingChanges(this.topic.hasChanges);
        if (this.topic.getErrors) {
            this.service.raiseHasErrors(this.topic.getErrors());
        }
        this.refreshStatus();
    };
    private readonly isAnyRecordAddedWithPaging = (): boolean => {
        let anyChanges = false;
        const dataRows = this.getDataRows();
        if (dataRows.some(x => x.status && x.status === rowStatus.Adding) && this.grid.wrapper.skip !== 0) {
            anyChanges = true;
        }

        return anyChanges;
    };

    private readonly refreshStatus = () => {
        const isValid = this.grid.isValid();
        let hasChanges = this.grid.isDirty();
        const dataRows = this.getDataRows();
        if (dataRows.some(x => x.status && x.status !== null)) {
            hasChanges = true;
            this.gridChanged.emit(this.grid);
        }
        this.caseDetailService.hasPendingChanges$.next(isValid && hasChanges);
        this.cdRef.detectChanges();
    };

    setDataRowErrors = (isError: boolean, rowKey: number): void => {
        const dataRows = this.getDataRows();
        const dr = dataRows.filter(x => { return x.rowKey === rowKey; });
        if (dr && dr.length > 0) {
            dr[0].error = isError;
        }
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'caseview.fileLocations.filePart',
            field: 'filePart',
            filter: this.showHistory,
            template: true
        }, {
            title: this.fileHistoryFromMaintenance ? 'caseview.fileLocations.lastFileLocation' : 'caseview.fileLocations.fileLocation',
            field: 'fileLocation',
            filter: this.showHistory,
            template: true
        }, {
            title: this.fileHistoryFromMaintenance ? 'caseview.fileLocations.lastBayNo' : 'caseview.fileLocations.bayNo',
            field: 'bayNo'
        }, {
            title: 'caseview.fileLocations.issuedBy',
            field: 'issuedBy',
            template: true
        }, {
            title: 'caseview.fileLocations.whenMoved',
            field: 'whenMoved',
            template: true
        }, {
            title: 'caseview.fileLocations.barCode',
            field: 'barCode',
            hidden: !this.permissions.CAN_REQUEST_CASE_FILE

        }];

        return columns;
    };

    ngOnDestroy(): void {
        if (this.subscription) {
            this.subscription.unsubscribe();
        }
    }
}