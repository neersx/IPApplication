import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, of, Subject } from 'rxjs';
import { take, takeUntil } from 'rxjs/operators';
import { FormControlWarning } from 'shared/component/forms/form-control-warning';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { AffectedCaseStatusEnum, RecordalRequestType, StepType } from '../affected-cases.model';
import { RequestRecordalService } from './request-recordal.service';

@Component({
    selector: 'ipx-affected-cases-set-agent',
    templateUrl: './request-recordal.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy, RequestRecordalService]
})
export class RequestRecordalComponent implements OnInit {
    @Input() selectedRowKeys: Array<string>;
    @Input() mainCaseId: number;
    @Input() isAllPageSelect: boolean;
    @Input() filterParams: any;
    @Input() deselectedRows: Array<string>;
    @Input() requestType: RecordalRequestType;
    @ViewChild('requestDateCtrl', { static: false }) requestDateCtrl: any;
    gridOptions: IpxGridOptions;
    onClose$ = new Subject();
    isSaveDisabled = true;
    @Input() showWebLink: Boolean;
    _resultsGrid: IpxKendoGridComponent;
    @ViewChild('requestRecordalGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }
    get StepType(): typeof StepType {
        return StepType;
    }
    caseReference: Observable<string>;
    isSaving: boolean;
    showNextSteps: boolean;
    showAllSteps: boolean;
    requestedDate: Date = new Date();
    title: string;
    data: Array<any> = [];
    filteredData: Array<any> = [];
    isLoading = true;
    dateTitle = 'caseview.affectedCases.requestRecordal.dateOfRequest';
    showNextTitle = 'caseview.affectedCases.requestRecordal.showNextSteps';

    constructor(
        private readonly service: RequestRecordalService,
        private readonly translate: TranslateService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly sbsModalRef: BsModalRef,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService,
        private readonly dateHelperService: DateHelper) { }

    ngOnInit(): void {
        this.service.getRequestRecordal({
            caseId: this.mainCaseId,
            selectedRowKeys: this.selectedRowKeys,
            deSelectedRowKeys: this.deselectedRows,
            isAllSelected: this.isAllPageSelect,
            requestType: this.requestType,
            filter: this.filterParams
        }).subscribe((response) => {
            this.data = response;
            this.setData(response);
            this.isLoading = false;
            this._resultsGrid.search();
            this._resultsGrid.gridSelectionHelper.isSelectAll = true;
            this._resultsGrid.toggleSelectAll();
        });
        if (this.requestType === RecordalRequestType.Reject) {
            this.dateTitle = 'caseview.affectedCases.requestRecordal.dateOfRejection';
            this.showNextTitle = 'caseview.affectedCases.requestRecordal.showAllFiledSteps';
        }
        this.gridOptions = this.buildGridOptions();
        this.title = 'caseview.affectedCases.requestRecordal.';
        switch (this.requestType) {
            case RecordalRequestType.Request:
                this.title += 'requestTitle';
                break;
            case RecordalRequestType.Reject:
                this.title += 'rejectTitle';
                break;
            case RecordalRequestType.Apply:
                this.title += 'applyTitle';
                break;
            default:
                this.title += 'requestTitle';
                break;
        }
        this.caseReference = this.service.getCaseReference(this.mainCaseId);
        this.handleShortcuts();
    }

    private readonly subscribeRowSelectionChange = () => {
        this._resultsGrid.rowSelectionChanged.subscribe((event) => {
            this.enableDisableSave();
        });
    };

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.SAVE, (): void => { if (!this.isSaveDisabled) { this.onSave(); } }],
            [RegisterableShortcuts.REVERT, (): void => { this.close(); }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
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
            read$: () => {
                return of(this.filteredData);
            },
            columns: this.getColumns(),
            selectable: {
                mode: 'multiple',
                enabled: true
            },
            hasDisabledRows: true,
            selectedRecords: {
                rows: {
                    rowKeyField: 'sequenceNo',
                    selectedKeys: []
                }
            },
            customRowClass: (context) => {
                let returnValue = '';
                if (!context.dataItem.isEditable) {
                    returnValue += ' text-grey-highlight';
                }

                return returnValue;
            }
        };
    }

    onDateChanged(event: any): void {
        (this.requestDateCtrl.control as FormControlWarning).warnings = null;
        if (!this.requestDateCtrl.control.value) {
            this.showValidationErrors();
        } else {
            const isFutureDate = this.dateHelperService.toLocal(new Date()) < this.dateHelperService.toLocal(this.requestedDate);
            if (isFutureDate) {
                this.showFutureDateWarnings();
            }
            this.requestedDate = event;
        }
        this.enableDisableSave();
    }

    private showValidationErrors(): void {
        if (this.requestType === RecordalRequestType.Request) {
            this.requestDateCtrl.control.setErrors({ emptyRequestDate: true });
        }
        if (this.requestType === RecordalRequestType.Reject) {
            this.requestDateCtrl.control.setErrors({ emptyRejectDate: true });
        }
        if (this.requestType === RecordalRequestType.Apply) {
            this.requestDateCtrl.control.setErrors({ emptyApplyDate: true });
        }
    }

    private showFutureDateWarnings(): void {
        let warning = '';
        if (this.requestType === RecordalRequestType.Request) {
            warning = this.translate.instant('field.errors.futureRecordalDate');
        }
        if (this.requestType === RecordalRequestType.Reject) {
            warning = this.translate.instant('field.errors.futureRejectionDate');
        }
        if (this.requestType === RecordalRequestType.Apply) {
            warning = this.translate.instant('field.errors.futureApplyDate');
        }
        (this.requestDateCtrl.control as FormControlWarning).warnings = [warning];
    }

    enableDisableSave = () => {
        this.isSaveDisabled = this.requestDateCtrl.invalid || (this._resultsGrid && this._resultsGrid.gridSelectionHelper.rowSelection.length === 0)
            || !_.any(this._resultsGrid.getSelectedItems('isEditable'), (value) => { return value; });
    };

    toggleSteps = ($event: any, stepType: StepType): void => {
        const selectedRecords = this._resultsGrid.getSelectedItems('sequenceNo');
        if (stepType === StepType.NextSteps && this.showNextSteps) {
            this.showAllSteps = !this.showNextSteps;
        }
        if (stepType === StepType.AllSteps && this.showAllSteps) {
            this.showNextSteps = !this.showAllSteps;
        }
        if (this.showAllSteps) {
            Object.assign(this.filteredData, this.data);
        } else {
            this.setData(this.data);
        }
        if (selectedRecords.length > 0) {
            selectedRecords.forEach(row => {
                this.filteredData.map(data => {
                    if (data.sequenceNo === row) {
                        data.selected = true;
                    }
                });
            });
        }
        this._resultsGrid.search();
    };

    setData = (response: any): void => {
        const filteredData = this.requestType === RecordalRequestType.Request ?
            response.filter(row => row.status === AffectedCaseStatusEnum.NotFiled) :
            response.filter(row => row.status === AffectedCaseStatusEnum.Filed);

        if (!this.showNextSteps) {
            const groups = _.groupBy(filteredData, (value: any) => {
                return value.caseId + '#' + value.countryCode + '#' + value.officialNo;
            });

            this.filteredData = _.map(groups, (group: any) => {
                return group[0];
            });
        } else {
            this.filteredData = filteredData;
        }
    };

    onSave = (): any => {
        const rows = this._resultsGrid.getCurrentData().filter(x => x.selected && x.isEditable);
        const rowKeys = _.pluck(rows, 'sequenceNo');
        if (rowKeys.length === 0) { return; }
        this.isSaving = true;
        this.isSaveDisabled = true;
        this.service.onSaveRecordal(this.mainCaseId, rowKeys, this.requestedDate, this.requestType).subscribe((response) => {
            this.isSaving = false;
            if (response.result === 'success') {
                this.sbsModalRef.hide();
                this.onClose$.next('success');
            }
        });
    };

    close = (): any => {
        if (!this.isSaveDisabled) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.sbsModalRef.hide();
                    this.onClose$.next(false);
                });
        } else {
            this.sbsModalRef.hide();
            this.onClose$.next(false);
        }
    };

    encodeLinkData = (data: any) =>
        'api/search/redirect?linkData=' +
        encodeURIComponent(JSON.stringify(data));

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [
            {
                title: 'caseview.affectedCases.columns.caseRef',
                field: 'caseReference',
                template: true,
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.jurisdiction',
                field: 'country',
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.officialNo',
                field: 'officialNo',
                template: true,
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.stepId',
                field: 'stepId',
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.recordalType',
                field: 'recordalType',
                template: true,
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.status',
                field: 'status',
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.requestDate',
                field: 'requestDate',
                sortable: false,
                defaultColumnTemplate: DefaultColumnTemplateType.date
            },
            {
                title: this.requestType === RecordalRequestType.Reject ? 'caseview.affectedCases.columns.rejectedDate' : 'caseview.affectedCases.columns.recordalDate',
                field: 'recordDate',
                sortable: false,
                defaultColumnTemplate: DefaultColumnTemplateType.date
            }];

        return columns;
    };
}