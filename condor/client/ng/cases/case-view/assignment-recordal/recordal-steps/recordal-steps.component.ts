import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { DateService } from 'ajs-upgraded-providers/date-service.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { debounceTime, take } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { RecordalStep, RecordalStepElementForm } from '../affected-cases.model';
import { AffectedCasesService } from '../affected-cases.service';

@Component({
    selector: 'ipx-recordal-steps',
    templateUrl: './recordal-steps.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class RecordalStepsComponent implements OnInit {

    gridOptions: IpxGridOptions;
    @Input() canMaintain: boolean;
    @Input() caseKey: number;
    @Input() isHosted: boolean;
    selectedId: number;
    isAssignedStep: boolean;
    recordalType: any;
    dateFormat: any;
    isSaveDisabled = true;
    recordalStepsFormData = [];
    formGroup: any;
    onClose$ = new Subject();
    hasSaved: boolean;

    @ViewChild('recordalStepsGrid', { static: true }) resultsGrid: IpxKendoGridComponent;
    previousSelectedStep: any;

    constructor(private readonly cdr: ChangeDetectorRef,
        private readonly service: AffectedCasesService,
        private readonly sbsModalRef: BsModalRef,
        private readonly dateService: DateService,
        private readonly formBuilder: FormBuilder,
        private readonly notificationService: NotificationService,
        private readonly ipxNotificationService: IpxNotificationService,
        readonly translate: TranslateService) { }

    ngOnInit(): void {
        this.canMaintain = true;
        this.dateFormat = this.dateService.dateFormat;
        this.gridOptions = this.buildGridOptions();
        this.service.elementFormDataChanged$.pipe(debounceTime(500)).subscribe(stepElementFormData => {
            this.isSaveDisabled = stepElementFormData && stepElementFormData.length > 0
                ? !_.any(stepElementFormData, (formObj) => formObj.form.dirty)
                : true;

            this.isSaveDisabled = stepElementFormData && stepElementFormData.length > 0
                ? _.any(stepElementFormData, (formObj) => formObj.form.status === 'INVALID')
                : true;
            this.cdr.markForCheck();
        });
    }

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            pageable: false,
            reorderable: false,
            sortable: false,
            filterable: false,
            createFormGroup: this.createFormGroup.bind(this),
            enableGridAdd: this.isHosted && this.canMaintain,
            canAdd: this.isHosted && this.canMaintain,
            rowMaintenance: this.isHosted ? {
                canEdit: this.canMaintain,
                canDelete: this.canMaintain,
                rowEditKeyField: 'id'
            } : null,
            read$: () => {
                return this.service.getRecordalSteps(this.caseKey);
            },
            columns: this.getColumns(),
            onClearSelection: () => {
                this.selectedId = null;
                this.isAssignedStep = false;
                this.recordalType = null;
            },
            onDataBound: (data: any) => {
                if (data) {
                    _.each(data, (step: any) => {
                        step.showEditAttributes = step.isAssigned ? { display: false } : { display: true };
                        step.showDeleteAttributes = step.isAssigned ? { display: false } : { display: true };
                    });
                    let index = 0;
                    if (this.selectedId) {
                        index = this.getRowIndexForStep(this.selectedId);
                    }
                    if (index === null || index === -1) {
                        index = 0;
                    }
                    this.resultsGrid.focusRow(index);
                    this.dataItemClicked(data[index]);
                }
                this.cdr.markForCheck();
            }
        };
    }

    createFormGroup(dataItem: any): FormGroup {
        this.formGroup = this.formBuilder.group({
            recordalType: [dataItem.recordalType, { validators: [Validators.required] }],
            stepName: dataItem.stepName ? dataItem.stepName : 'Step ' + this.getNextStepNo(),
            modifiedDate: this.dateService.format(dataItem.modifiedDate ? dataItem.modifiedDate : new Date()),
            isAssigned: dataItem.isAssigned,
            id: dataItem.id ? dataItem.id : this.getNextStepNo(),
            status: dataItem.status ? dataItem.status : rowStatus.Adding,
            stepId: dataItem.stepId ? dataItem.stepId : this.getNextStepNo(),
            caseId: this.caseKey
        });

        return this.formGroup;
    }

    cancelRowEdit = (rowKey: Event) => {
        const changedItem = this.getDataRows().filter((step) => {
            return step.id.toString() === rowKey;
        })[0];

        if (changedItem) {
            const hasSameStepId = this.getDataRows().filter((step) => {
                return step.stepId === changedItem.stepId && step.id !== changedItem.id;
            });

            if (hasSameStepId.length > 0) {
                this.reArrangeSteps(changedItem, false);
                this.cdr.detectChanges();
            }
        }
        this.service.clearStepElementRowFormData(changedItem.stepId);
        this.formGroup = null;
        this.dataItemClicked(changedItem);
        this.isSaveDisabled = !this.isFormDirty();
    };

    onDeleteRow = (data: any): void => {
        this.reArrangeSteps(data, true);
        if (data.status === rowStatus.Adding && this.selectedId === data.id && this.getDataRows().length > 0) {
            this.service.clearStepElementRowFormData(data.id);
            this.formGroup = null;
            this.resultsGrid.focusRow(0);
            this.dataItemClicked(this.getDataRows()[0]);
        } else {
            const rowIndex = this.getRowIndexForStep(this.selectedId);
            this.resultsGrid.focusRow(rowIndex);
        }
        this.isSaveDisabled = !this.isFormDirty();
    };

    private reArrangeSteps(data: RecordalStep, isDeleted: boolean): any {
        const itemsToBeChanged = this.getDataRows().filter((step) => {
            return step.stepId >= data.stepId && step.id !== data.id && step.status !== rowStatus.deleting;
        });

        itemsToBeChanged.forEach(r => {
            r.stepId = isDeleted ? r.stepId - 1 : r.stepId + 1;
            r.stepName = 'Step ' + r.stepId;
            const form = this.resultsGrid.rowEditFormGroups[r.id];
            if (form) {
                form.value.stepId = r.stepId;
                form.value.stepName = r.stepName;
            }
        });
    }

    private readonly getDataRows = (): Array<any> => {
        return Array.isArray(this.resultsGrid.wrapper.data) ? this.resultsGrid.wrapper.data : (this.resultsGrid.wrapper.data).data;
    };

    private readonly getNextStepNo = (index = null): number => {
        if (index) { return index + 1; }
        const rows = this.getDataRows().filter(x => x !== undefined);
        const lastStep = rows.length === 0 ? 0 : rows[rows.length - 1].stepId;

        return lastStep + 1;
    };

    onSave(): any {
        this.updateStepElements();
        const requestData = this.getFormDataRows();
        this.service.saveRecordalSteps(requestData).subscribe(res => {
            if (res && res.errors) {
                let message = '';
                res.errors.forEach((err) => {
                    if (err.message !== null) {
                        message += this.translate.instant(err.message).replace('{value}', err.field) + '\n';
                    }
                });
                this.ipxNotificationService.openAlertModal('', message);
            } else {
                this.hasSaved = true;
                this.notificationService.success();
                this.resetForm();
                this.resultsGrid.search();
                this.service.clearStepElementFormData();
                this.isSaveDisabled = true;
            }
        });
    }

    resetForm(): void {
        this.resultsGrid.rowEditFormGroups = null;
        this.gridOptions.formGroup = undefined;
        this.formGroup = null;
        this.resultsGrid.currentEditRowIdx = this.selectedId;
        this.resultsGrid.closeRow();
        this.cdr.markForCheck();
    }

    private updateStepElements(): any {
        if (_.any(this.service.stepElementForm, (formObj) => formObj.form.dirty)) {
            const previousSelectedStepId = this.service.rowSelected$.getValue().stepId;
            const previousStep = this.getDataRows().filter((step) => {
                return step.id === previousSelectedStepId;
            })[0];
            if (previousStep) {
                previousStep.caseRecordalStepElements = this.service.updateOriginalRecordalElements();
                if (this.resultsGrid.rowEditFormGroups) {
                    const form = this.resultsGrid.rowEditFormGroups[previousStep.id];
                    if (form) {
                        form.value.caseRecordalStepElements = previousStep.caseRecordalStepElements;
                    }
                }
            }
        }
    }

    private readonly getFormDataRows = (): any => {
        const result = [];
        if (this.resultsGrid.rowEditFormGroups) {
            const keys = Object.keys(this.resultsGrid.rowEditFormGroups);
            keys.forEach(key => {
                const formData = this.resultsGrid.rowEditFormGroups[key].value;
                result.push(formData);
            });
        }
        const rowsWithStepElementsChange = this.getDataRows().filter((step) => {
            return step.caseRecordalStepElements && step.caseRecordalStepElements.length > 0;
        });
        rowsWithStepElementsChange.forEach((step) => {
            const stepExists = result.find((s) => {
                return s.id === step.id;
            });
            if (!stepExists) {
                result.push(step);
            }
        });

        return result;
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [
            {
                title: 'caseview.recordal.steps',
                field: 'stepName',
                sortable: false
            }, {
                title: 'caseview.recordal.recordalType',
                field: 'recordalType',
                template: true,
                sortable: false
            }, {
                title: 'caseview.recordal.modifiedDate',
                field: 'modifiedDate',
                defaultColumnTemplate: DefaultColumnTemplateType.date,
                type: 'date',
                sortable: false
            }];

        return columns;
    };

    onStepAddOrEdit = ($event) => {
        this.resultsGrid.focusRow($event.rowIndex);
        this.dataItemClicked($event.dataItem);
    };

    dataItemClicked = (event: RecordalStep): void => {
        if (!event) { return; }
        this.previousSelectedStep = this.service.rowSelected$.getValue();
        if (this.previousSelectedStep) {
            const existingFormData = _.find(this.service.stepElementForm, (data: RecordalStepElementForm) => {
                return data.stepId === this.previousSelectedStep.stepId;
            });
            if (existingFormData && existingFormData.form.status === 'INVALID' && event.id !== this.previousSelectedStep.stepId) {
                this.ipxNotificationService.openAlertModal('Warning', 'caseview.recordal.mandatoryWarning');
                const rowIndex = this.getRowIndexForStep(this.previousSelectedStep.stepId);
                this.resultsGrid.focusRow(rowIndex);
                this.cdr.detectChanges();
            } else if (this.resultsGrid.rowEditFormGroups && this.resultsGrid.rowEditFormGroups[this.previousSelectedStep.stepId]) {
                const step = this.resultsGrid.rowEditFormGroups[this.previousSelectedStep.stepId];
                this.processRecordalRelments(step.value);
            }
        }
        this.processRecordalRelments(event);
        this.loadRecordalElement(event);
    };

    processRecordalRelments = (event) => {
        this.selectedId = event && event.id != null ? event.id : null;
        this.isAssignedStep = event && event.isAssigned != null ? event.isAssigned : false;
        this.recordalType = event.status === rowStatus.Adding || event.status === rowStatus.editing
            ? this.resultsGrid.rowEditFormGroups[event.id].value.recordalType
            : this.recordalType = event.recordalType;

        if (this.recordalType != null) {
            this.updateStepElements();
        }
    };

    private getRowIndexForStep(id: number): number {
        return _.findIndex(this.resultsGrid.wrapper.data as _.List<any>, { id });
    }

    loadRecordalElement = (selected: RecordalStep) => {
        const stepElements = { stepId: selected.id, recordalStepElement: selected.caseRecordalStepElements, recordalType: this.recordalType ? this.recordalType.key : null };
        this.service.rowSelected$.next(stepElements);
    };

    onModelChange = ($event: any, dataItem: RecordalStep) => {
        this.recordalType = $event;
        dataItem.caseRecordalStepElements = null;
        this.loadRecordalElement(dataItem);
        this.isSaveDisabled = !this.isFormDirty();
    };

    close(): void {
        if (this.isFormDirty()) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.service.clearStepElementFormData();
                    this.sbsModalRef.hide();
                    this.onClose$.next(this.hasSaved);
                });
        } else {
            this.service.clearStepElementFormData();
            this.sbsModalRef.hide();
            this.onClose$.next(this.hasSaved);
        }
    }

    isFormDirty = (): boolean => {
        this.resultsGrid.checkChanges();
        const isValid = this.resultsGrid.isValid();
        const dataRows = this.getDataRows();
        const hasChanges = dataRows.some(x => x && x.status && x.status !== null) && isValid;

        return hasChanges || _.any(this.service.stepElementForm, (formObj) => formObj.form.dirty);
    };

    disableSave(value): void {
        this.isSaveDisabled = value;
    }
}