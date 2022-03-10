import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { ItemType, SearchColumnSaveDetails, SearchColumnState } from './search-columns.model';
import { SearchColumnsService } from './search-columns.service';

@Component({
    selector: 'search-columns-addedit',
    templateUrl: './search-column.maintenance.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class SearchColumnMaintenanceComponent implements OnInit {
    columnId: number;
    queryContextKey: number;
    appliesToInternal: Boolean;
    displayFilterBy: Boolean;
    internalContext: number;
    externalContext: number;
    states: string;
    searchColumnTypeahead: any;
    userColumnTypehead: any;
    viewDefault: any;
    gridOptions: IpxGridOptions;
    columnGroupExtendQuery: Function;
    searchColumnExtendQuery: Function;
    searchColumn: SearchColumnSaveDetails = new SearchColumnSaveDetails();
    searchColumnState = SearchColumnState;
    isDisableDocItem = true;
    isDisableParameter = true;
    displayNavigation: Boolean;
    isAvailableColumnEdit: Boolean;
    modalRef: BsModalRef;
    currentKey: number;
    navData: {
        keys: Array<any>,
        totalRows: number,
        pageSize: number,
        fetchCallback(currentIndex: number): any
    };
    @Output() readonly searchColumnRecord: EventEmitter<any> = new EventEmitter();
    @ViewChild('maintenanceForm', { static: true }) ngForm: NgForm;

    constructor(private readonly bsModalRef: BsModalRef, private readonly searchColumnService: SearchColumnsService,
        private readonly notificationService: NotificationService, private readonly ipxNotificationService: IpxNotificationService,
        private readonly cdRef: ChangeDetectorRef, private readonly navService: GridNavigationService) { }

    ngOnInit(): void {
        if (this.states === this.searchColumnState.Updating) {
            if (this.displayNavigation) {
                this.navData = {...this.navService.getNavigationData(),
                    fetchCallback: (currentIndex: number): any => {
                        return this.navService.fetchNext$(currentIndex).toPromise();
                    }};
                this.currentKey = this.navData.keys.filter(k => k.value === this.columnId.toString())[0].key;
            }

            this.getColumnDetails();
            this.gridOptions = this.buildGridOptions();
        }
        this.columnGroupExtendQuery = this.extendColumnGroupQuery.bind(this);
        this.searchColumnExtendQuery = this.extendSearchColumnQuery.bind(this);
    }

    getColumnDetails = () => {
        this.searchColumnService
                .searchColumn(this.queryContextKey, this.columnId)
                .subscribe((response) => {
                    this.searchColumn = response;
                    if (this.searchColumn.columnName) {
                        this.onColumnNameChange(this.searchColumn.columnName);
                    }
                    this.cdRef.markForCheck();
                });
    };

    getNextColumnDetail(next: number): any {
        this.columnId = next;
        this.markFormPristine(this.ngForm);
        this.getColumnDetails();
    }

    markFormPristine = (form: NgForm): void => {
        Object.keys(form.controls).forEach(control => {
            form.controls[control].markAsPristine();
        });
    };

    validate = () => {
        let isValid: Boolean = true;
        if (!this.searchColumn.displayName) {
            this.setError('displayName');
            isValid = false;
        }
        if (!this.searchColumn.columnName) {
            this.setError('columnName');
            isValid = false;
        }
        if (this.searchColumn.columnName
            && this.searchColumn.columnName.isUserDefined && !this.searchColumn.docItem) {
            this.setError('dataItem');
            isValid = false;
        }
        if (this.searchColumn.columnName
            && this.searchColumn.columnName.isUserDefined && !this.searchColumn.docItem) {
            this.setError('dataItem');
            isValid = false;
        }
        if (this.searchColumn.columnName
            && this.searchColumn.columnName.isQualifierAvailable && !this.searchColumn.parameter) {
            this.setError('parameter');
            isValid = false;
        }
        if (this.searchColumn.columnName
            && this.searchColumn.docItem) {
            isValid = this.validateItemType(this.searchColumn.docItem);
        }

        return isValid;
    };

    saveSearchColumn(): void {
        if (!this.validate()) {
            return;
        }

        this.searchColumnService.inUseSearchColumns = [];
        this.searchColumn.queryContextKey = this.queryContextKey;

        if (this.states === this.searchColumnState.Adding) {
            this.searchColumnService.saveSearchColumn(this.searchColumn).subscribe((response) => {
                this.afterSave(response);
            });
        } else {
            this.searchColumnService.updateSearchColumn(this.searchColumn).subscribe((response) => {
                this.afterSave(response);
            });
        }
    }

    afterSave = (response: any) => {
        if (response.result === 'success') {
            this.searchColumnService.savedSearchColumns.push(response.updatedId);
            this.notificationService.success();
            this.markFormPristine(this.ngForm);
            this.cdRef.markForCheck();
            if (!this.displayNavigation) {
                this.emitSearchColumnParams({
                    runSearch: true,
                    updatedId: response.updatedId
                });
            }
        } else {
            const errors = response.errors;
            const message = this.getError(['dataItem', 'parameter'], errors).message;
            this.ipxNotificationService.openAlertModal('modal.unableToComplete', message, errors);
            this.setError('dataItem');
            this.setError('parameter');
        }
    };

    getError = (fields: Array<string>, errors: Array<any>) => {
        return _.find(errors, (error: any) => {
            return _.contains(fields, error.field);
        });
    };

    setError = (control: string) => {
        this.ngForm.controls[control].markAsTouched();
        this.ngForm.controls[control].markAsDirty();
        this.ngForm.controls[control].setErrors({ required: true });
    };

    onClose(): void {
        if (this.ngForm.dirty) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();
            this.modalRef.content.confirmed$.subscribe(() => {
                this.bsModalRef.hide();
                this.emitSearchColumnParams({
                    runSearch: this.displayNavigation
                });
            });
        } else {
            this.bsModalRef.hide();
            this.emitSearchColumnParams({
                runSearch: this.displayNavigation
            });
        }
    }

    isFormDirty = () => {
        return this.ngForm.dirty;
    };

    emitSearchColumnParams = (params: any): void => {
        this.searchColumnRecord.emit(params);
    };

    private buildGridOptions(): IpxGridOptions {

        return {
            sortable: false,
            read$: () => this.searchColumnService.searchColumnUsage(this.columnId),
            columns: [{
                field: 'searchType', title: 'Type of Search', width: 20, sortable: false
            }, {
                field: 'columnDisplayName', title: 'Column', width: 20, sortable: false
            }]
        };
    }

    extendColumnGroupQuery(query): any {
        const extended = _.extend({}, query, {
            queryContext: this.queryContextKey
        });

        return extended;
    }

    extendSearchColumnQuery(query): any {
        const extended = _.extend({}, query, {
            queryContext: this.queryContextKey
        });

        return extended;
    }

    extendedParamGroupPicklist = (): any => {
        return {
            contextId: this.queryContextKey
        };
    };

    disable = (): boolean => {
        return !this.ngForm.dirty;
    };

    onColumnNameChange = (value: any): void => {
        this.isDisableParameter = value ? !value.isQualifierAvailable : true;
        if (this.isDisableParameter) {
            this.searchColumn.parameter = null;
            if (this.ngForm.controls.parameter) {
                this.ngForm.controls.parameter.markAsUntouched();
            }
            if (this.ngForm.controls.parameter) {
                this.ngForm.controls.parameter.markAsPristine();
            }
        }
        this.isDisableDocItem = value ? !value.isUserDefined : true;
        if (this.isDisableDocItem) {
            this.searchColumn.docItem = null;
            if (this.ngForm.controls.dataItem) {
                this.ngForm.controls.dataItem.markAsUntouched();
            }
            if (this.ngForm.controls.dataItem) {
                this.ngForm.controls.dataItem.markAsPristine();
            }
        }
        this.searchColumn.dataFormat = value ? value.dataFormat : null;
    };

    validateItemType = (dataItem: any): Boolean => {
        if (dataItem && (dataItem.itemType === ItemType.StoredProcedure
             || dataItem.itemType === ItemType.StoredProcedureExternalDataSource)) {
            this.ngForm.controls.dataItem.setErrors({ 'searchColumn.invalidDocitem': true });

            return false;
        }

        return true;
    };
}