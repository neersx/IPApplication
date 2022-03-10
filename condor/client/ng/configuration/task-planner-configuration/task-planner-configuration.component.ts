import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, ValidationErrors, Validators } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { TagsErrorValidator } from 'shared/component/typeahead/ipx-typeahead/typeahead.config.provider';
import * as _ from 'underscore';
import { TaskPlannerTabConfigItem } from './task-planner-configuration.model';
import { TaskPlannerConfigurationService } from './task-planner-configuration.service';
@Component({
    selector: 'task-planner-configuration',
    templateUrl: './task-planner-configuration.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class TaskPlannerConfigurationComponent implements OnInit {
    gridOptions: IpxGridOptions;
    @ViewChild('ipxKendoGridRef', { static: false }) grid: any;
    currentRowIndexs: Array<number> = [];

    defaultRowKey: any;
    constructor(
        private readonly service: TaskPlannerConfigurationService,
        private readonly cdr: ChangeDetectorRef,
        private readonly formBuilder: FormBuilder,
        private readonly notificationService: NotificationService
    ) {
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
    }

    private buildGridOptions(): IpxGridOptions {

        const options: IpxGridOptions = {
            sortable: false,
            showGridMessagesUsingInlineAlert: false,
            autobind: true,
            reorderable: false,
            pageable: false,
            enableGridAdd: true,
            canAdd: true,
            selectable: {
                mode: 'single'
            },
            read$: (queryParams) => {
                return this.service.getProfileTabData();
            },
            rowMaintenance: {
                canDelete: true,
                canEdit: true,
                rowEditKeyField: 'id'
            },
            columns: this.getColumns(),
            onDataBound: (data: any) => {
                const defaultRow = data.find(x => !x.profile);
                defaultRow.showDeleteAttributes = { display: false };
                defaultRow.isDefault = true;
                this.defaultRowKey = defaultRow.id;

                this.cdr.markForCheck();
            },
            createFormGroup: this.createFormGroup.bind(this)
        };

        return options;
    }

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'taskPlannerConfig.column.profile',
            field: 'profile',
            sortable: false,
            template: true
        }, {
            title: 'taskPlannerConfig.column.tab1',
            field: 'tab1',
            sortable: false,
            template: true
        }, {
            title: 'taskPlannerConfig.column.locked',
            field: 'tab1Locked',
            sortable: false,
            template: true
        }, {
            title: 'taskPlannerConfig.column.tab2',
            field: 'tab2',
            sortable: false,
            template: true
        }, {
            title: 'taskPlannerConfig.column.locked',
            field: 'tab2Locked',
            sortable: false,
            template: true
        }, {
            title: 'taskPlannerConfig.column.tab3',
            field: 'tab3',
            sortable: false,
            template: true
        }, {
            title: 'taskPlannerConfig.column.locked',
            field: 'tab3Locked',
            sortable: false,
            template: true
        }];

        return columns;
    };

    private createFormGroup(dataItem: any): FormGroup {
        const controls = {
            profile: new FormControl({ value: null, disabled: dataItem.isDefault }, this.checkForDuplicateProfile),
            tab1: new FormControl(undefined, Validators.required),
            tab1Locked: new FormControl(undefined),
            tab2: new FormControl(undefined, Validators.required),
            tab2Locked: new FormControl(undefined),
            tab3: new FormControl(undefined, Validators.required),
            tab3Locked: new FormControl(undefined)
        };
        const formGroup = this.formBuilder.group(controls);

        if (dataItem.status === rowStatus.editing) {
            formGroup.controls.profile.setValue(dataItem.profile);
            formGroup.controls.tab1.setValue(dataItem.tab1);
            formGroup.controls.tab1Locked.setValue(dataItem.tab1Locked);
            formGroup.controls.tab2.setValue(dataItem.tab2);
            formGroup.controls.tab2Locked.setValue(dataItem.tab2Locked);
            formGroup.controls.tab3.setValue(dataItem.tab3);
            formGroup.controls.tab3Locked.setValue(dataItem.tab3Locked);
        }

        this.gridOptions.formGroup = formGroup;
        this.cdr.detectChanges();

        return formGroup;
    }

    discard(): void {
        this.resetForm();
        this.grid.search();
    }

    getRowIndex = (event): void => {
        if (!this.currentRowIndexs.some(x => x === event)) {
            this.currentRowIndexs.push(event);
        }
    };

    getEditedRowIndex = (event): void => {
        if (!this.currentRowIndexs.some(x => x === event.rowIndex)) {
            this.currentRowIndexs.push(event.rowIndex);
        }
    };

    private resetForm(): void {
        this.grid.rowEditFormGroups = null;
        this.gridOptions.formGroup = null;
        this.currentRowIndexs.forEach(key => {
            this.grid.currentEditRowIdx = key;
            this.grid.closeRow();
        });
        this.cdr.detectChanges();
    }

    getExtendQuery = (query: any): any => {
        return {
            ...query,
            retrievePublicOnly: true
        };
    };

    isGridDirty(): boolean {
        if (!this.grid) {
            return false;
        }
        const formGroups = this.grid.rowEditFormGroups || {};

        return Object.keys(formGroups).length > 0;
    }

    isGridValid = (): boolean => {
        if (!this.grid) {
            return false;
        }
        const formGroups = this.grid.rowEditFormGroups || {};
        const formKeys = Object.keys(formGroups);
        let isValid = true;
        formKeys.forEach(key => {
            const dataItem = formGroups[key].value;
            if (!dataItem || (+key !== this.defaultRowKey && (!dataItem.profile || dataItem.profile.isError))
                || !dataItem.tab1 || dataItem.tab1.isError
                || !dataItem.tab2 || dataItem.tab2.isError
                || !dataItem.tab3 || dataItem.tab3.isError) {
                isValid = false;
            }
        });

        return isValid;
    };

    private readonly checkForDuplicateProfile = (c: AbstractControl): ValidationErrors | null => {
        this.cdr.markForCheck();
        if (c.value && c.dirty) {
            const duplicateRows = this.getDataItems(true).filter(x => x.profile && x.profile.key === c.value.key && !x.isDeleted);

            if (duplicateRows.length > 0) {
                const errorObj: TagsErrorValidator = {
                    validator: { duplicate: 'duplicate' },
                    keys: null,
                    keysType: null,
                    applyOnChange: true
                };

                return { duplicate: 'duplicate', errorObj };
            }
        }
        if (!c.value) {
            const errorObj: TagsErrorValidator = {
                validator: { required: 'required' },
                keys: null,
                keysType: null,
                applyOnChange: true
            };

            return { required: 'required', errorObj };
        }

        return null;
    };

    private readonly getDataItems = (includeUnchanged = false): Array<TaskPlannerTabConfigItem> => {
        const finalData: Array<TaskPlannerTabConfigItem> = [];
        const formGroups = this.grid.rowEditFormGroups || {};
        const formKeys = Object.keys(formGroups);
        const data = this.grid.getCurrentData();
        data.forEach(d => {
            if (d) {
                const key = String(d[this.gridOptions.rowMaintenance.rowEditKeyField]);
                if (formKeys.indexOf(key) !== -1) {
                    const obj = formGroups[key].value;
                    obj.isDeleted = d.status === rowStatus.deleting;
                    obj.id = d.status === rowStatus.editing ? key : null;
                    finalData.push(obj);
                } else if (includeUnchanged) {
                    finalData.push(d);
                }
            }
        });

        return finalData;
    };

    onSave = (): void => {
        const dataRows = this.getDataItems();
        if (!this.isGridValid() || dataRows.length === 0) {
            return;
        }
        this.service.save(dataRows).subscribe(response => {
            this.resetForm();
            this.grid.search();
            this.notificationService.success();
        });
    };
}