import { DatePipe } from '@angular/common';
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { TimeRecordingService } from 'accounting/time-recording/time-recording-service';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { debounceTime, distinctUntilChanged, take, takeWhile } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { DisbursementDissectionWipComponent } from './disbursement-dissection-wip/disbursement-dissection-wip.component';
import { DisbursementDissectionWip } from './disbursement-dissection.models';
import { DisbursementDissectionService } from './disbursement-dissection.service';

@Component({
    selector: 'disbursement-dissection',
    templateUrl: './disbursement-dissection.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DisbursementDissectionComponent implements OnInit, AfterViewInit {
    formGroup: any;
    viewData: any;
    gridOptions: IpxGridOptions;
    isItemDateWarningSuppressed: boolean;
    unallocatedAmount$: Observable<number>;
    unallocatedAmount: BehaviorSubject<number> = new BehaviorSubject<number>(null);
    numericStyle = { width: '102%', marginLeft: '-10px' };
    errorStyle = { marginLeft: '-20px' };
    currency: string;
    oldCurrency: any;
    disableSave = true;
    ddWips: Array<DisbursementDissectionWip> = [];
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
    isAddedAnother: boolean;
    lastAddedItemId: number;
    @ViewChild('totalAmountEl', { static: false }) totalAmountEl: any;
    @ViewChild('disbursementGrid', { static: false }) grid: IpxKendoGridComponent;

    constructor(private readonly service: DisbursementDissectionService, private readonly fb: FormBuilder,
        private readonly datePipe: DatePipe, private readonly timeService: TimeRecordingService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly modalService: IpxModalService,
        private readonly notificationService: NotificationService) {
        this.unallocatedAmount$ = this.unallocatedAmount.asObservable();
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.createFormGroup();
        this.service.getSupportData$().subscribe((response: any) => {
            this.viewData = response;
            this.currency = response.localCurrency;
            this.setDefaultEntity();
        });
    }

    setDefaultEntity(): any {
        const defaultEntity = _.filter(this.viewData.entities, (r: any) => {
            return r.isDefault;
        });
        this.formGroup.patchValue({ entity: _.first(defaultEntity).entityKey });
        this.formGroup.controls.entity.markAsPristine();
    }

    ngAfterViewInit(): void {
        this.disableSave = this.getSaveButtonStatus();
        this.formGroup.controls.currency.valueChanges
            .pipe(debounceTime(500), distinctUntilChanged())
            .subscribe((value) => {
                this.currencyOnChange(value);
            });
    }

    createFormGroup = (): FormGroup => {
        const maxAllowedValue = 99999999999.99;
        this.formGroup = this.fb.group({
            entity: new FormControl(),
            associate: new FormControl(),
            transactionDate: new FormControl(new Date()),
            invoiceNo: new FormControl(),
            currency: new FormControl(),
            verificationNo: new FormControl(),
            isCredit: new FormControl(false),
            totalAmount: new FormControl(null, Validators.compose([Validators.min(1), Validators.max(maxAllowedValue)]))
        });

        return this.formGroup;
    };

    isPageDirty = (): boolean => {
        return this.formGroup.hasPendingChanges;
    };

    validateItemDate = (date: any) => {
        if (date) {
            this.isItemDateWarningSuppressed = false;
            const transDate = this.datePipe.transform(this.timeService.toLocalDate(date, true), 'yyyy-MM-dd');
            this.service.validateItemDate(transDate).subscribe((res: any) => {
                if (res && res.hasError) {
                    if (res.validationErrorList[0].warningCode) {
                        const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', 'field.errors.ac124', 'Proceed', 'Cancel');
                        confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
                            this.isItemDateWarningSuppressed = true;
                        });
                        confirmationRef.content.cancelled$.pipe(takeWhile(() => !!confirmationRef))
                            .subscribe(() => { this.formGroup.controls.transactionDate.setValue(new Date()); });
                    } else {
                        switch (res.validationErrorList[0].errorCode) {
                            case 'AC126': return this.formGroup.controls.transactionDate.setErrors({ ac126: true });
                            case 'AC208': return this.formGroup.controls.transactionDate.setErrors({ ac208: true });
                            default: {
                                break;
                            }
                        }
                    }
                    this.cdRef.markForCheck();
                }
            });
        } else {
            this.formGroup.controls.transactionDate.setValue(new Date());
        }
        this.formGroup.controls.transactionDate.markAsPristine();
        this.cdRef.markForCheck();
    };

    totalAmountChange = (value: number) => {
        this.updateChangeStatus();
        this.getSaveButtonStatus();
    };

    currencyOnChange = (value: any) => {
        if (value && value.code) {
            const rows: any = this.grid.wrapper.data;
            if (rows.length > 0) {
                this.disableSave = this.getSaveButtonStatus();
                const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', 'accounting.wip.warningMsgs.changeCurrency', 'Proceed', 'Cancel');
                confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
                    this.currency = value ? value.code : this.viewData.localCurrency;
                    this.oldCurrency = value;
                    this.unallocatedAmount.next(this.formGroup.controls.totalAmount.value);
                    this.grid.clear();
                });
                confirmationRef.content.cancelled$.pipe(takeWhile(() => !!confirmationRef))
                    .subscribe(() => { this.formGroup.controls.currency.setValue(this.oldCurrency, { emitEvent: false }); });
            } else {
                this.oldCurrency = value;
            }
        }
        this.cdRef.markForCheck();
    };

    submit = () => {
        if (!this.formGroup.valid) { return; }
        if (this.unallocatedAmount.getValue() !== 0 || this.getTotalDissectionAmount() !== this.formGroup.value.totalAmount) {
            this.notificationService.alert({
                title: 'modal.unableToComplete',
                message: 'accounting.wip.disbursements.amountMismatched'
            });

            return;
        }
        const request = this.prepareDisbursementRequest();
        this.service.submitDisbursement(request).subscribe(() => {
            this.reset();
            this.notificationService.info({
                title: 'wip.splitWip.info',
                message: 'accounting.wip.disbursements.success',
                continue: 'Ok'
            });
        });
    };

    getTotalDissectionAmount(): number {
        if (this.grid.wrapper.data) {
            const rows: any = this.grid.wrapper.data;

            return this.formGroup.value.currency ? rows.map(x => x.foreignAmount).reduce((a, b) => a + b)
                : rows.map(x => x.amount).reduce((a, b) => a + b);
        }

        return 0;
    }

    reset = (): void => {
        this.formGroup.reset();
        this.formGroup.patchValue({ transactionDate: new Date(), totalAmount: null });
        this.totalAmountEl.el.nativeElement.querySelector('input').value = null;
        this.totalAmountEl.showError$.next(false);
        this.formGroup.controls.totalAmount.markAsPristine();
        this.formGroup.markAsPristine();
        this.grid.clear();
        this.grid.refresh();
        this.grid.wrapper.data = [];
        this.disableSave = this.getSaveButtonStatus();
        this.setDefaultEntity();
        this.cdRef.detectChanges();
    };

    getSaveButtonStatus(): any {
        const rows: any = this.grid.wrapper.data;
        if (this.formGroup.valid && rows.length > 0) {
            this.disableSave = false;

            return false;
        }
        this.disableSave = true;

        return true;
    }

    prepareDisbursementRequest = (): any => {
        const wip = new DisbursementDissectionWip();

        return {
            dissectedDisbursements: wip.prepareGridDataRequest(this.grid, this.formGroup),
            entityKey: this.formGroup.value.entity ? this.formGroup.value.entity : null,
            transDate: this.formGroup.value.transactionDate,
            associateKey: this.formGroup.value.associate ? this.formGroup.value.associate.key : null,
            associateNameCode: this.formGroup.value.associate ? this.formGroup.value.associate.code : null,
            associateName: this.formGroup.value.associate ? this.formGroup.value.associate.displayName : null,
            currency: this.formGroup.value.currency ? this.formGroup.value.currency.code : null,
            currencyDescription: this.formGroup.value.currency ? this.formGroup.value.currency.description : null,
            totalAmount: this.formGroup.value.totalAmount,
            creditWIP: this.formGroup.value.isCredit,
            invoiceNo: +this.formGroup.value.invoiceNo,
            verificationNo: +this.formGroup.value.verificationNo
        };

    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            reorderable: true,
            sortable: true,
            enableGridAdd: true,
            canAdd: true,
            gridMessages: {
                noResultsFound: ''
            },
            rowMaintenance: {
                canEdit: true,
                canDelete: true,
                rowEditKeyField: 'id',
                width: '75px'
            },
            maintainFormGroup$: this.maintainFormGroup$,
            read$: (queryParams) => {
                return of(this.ddWips);
            },
            columns: this.getColumns()
        };
    }

    onRowAddedOrEdited = (data: any): void => {
        const lastDataItem = { ...data.dataItem };
        if (this.isAddedAnother) {
            const lastRow = this.getDataRows()[this.lastAddedItemId];
            if (lastRow) {
                lastDataItem.name = lastRow.name;
                lastDataItem.case = lastRow.case;
                lastDataItem.disbursement = lastRow.disbursement;
                lastDataItem.narrative = lastRow.narrative;
                lastDataItem.debitNoteText = lastRow.debitNoteText;
                switch (this.viewData.staffManualEntryforWIP) {
                    case 1:
                        lastDataItem.staff = null;
                        break;
                    case 2:
                        lastDataItem.staff = lastRow.staff;
                        break;
                    default:
                        if (this.service.allDefaultWips.length > 0) {
                            const defaultWip = this.service.allDefaultWips[0];
                            lastDataItem.staff = { key: defaultWip.staffKey, code: defaultWip.staffCode, displayName: defaultWip.staffName };
                        }
                        break;
                }
            }
        }
        const modal = this.modalService.openModal(DisbursementDissectionWipComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                dataItem: lastDataItem,
                isAdding: data.dataItem.status === rowStatus.Adding && !data.dataItem.disbursement,
                rowIndex: data.rowIndex,
                transactionDate: this.formGroup.controls.transactionDate.value,
                currency: this.formGroup.controls.currency.value ? this.formGroup.controls.currency.value.code : null,
                entityKey: this.formGroup.controls.entity.value,
                localCurrency: this.viewData.localCurrency,
                grid: this.grid
            }
        });
        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event, data);
            }
        );
    };

    onCloseModal(event, data): void {
        this.isAddedAnother = false;
        if (event.success) {
            const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: event.formGroup } as any;
            this.gridOptions.maintainFormGroup$.next(rowObject);
            this.updateChangeStatus();
            if (this.service.isAddAnotherChecked.getValue()) {
                this.gridOptions.maintainFormGroup$.next(null);
                this.isAddedAnother = true;
                this.lastAddedItemId = data.rowIndex;
                this.grid.addRow();
            } else {
                if (this.modalService && this.modalService.modalRef) {
                    this.modalService.modalRef.hide();
                }
            }
        } else {
            this.removeAddedEmptyRow(data);
        }

        this.disableSave = this.getSaveButtonStatus();
        this.cdRef.detectChanges();
    }

    removeAddedEmptyRow = (data): any => {
        if (data.dataItem.status === rowStatus.Adding) {
            const rows: any = this.grid.wrapper.data;
            this.grid.wrapper.data = rows.filter(x => x && x.amount);
            const emptyRowIndex = rows.findIndex(x => !x.status);
            if (emptyRowIndex > -1) {
                this.grid.rowDeleteHandler(this, emptyRowIndex, this.formGroup.value);
                if (emptyRowIndex === 0) {
                    this.grid.clear();
                }
            }
        }
    };

    updateChangeStatus = (): void => {
        this.grid.checkChanges();
        const dataRows = this.getDataRows();
        const allocated = dataRows.reduce((sum, d) => sum + (this.formGroup.controls.currency.value ? d.foreignAmount : d.amount), 0);
        const unallocatedAmount = this.formGroup.controls.totalAmount.value ? this.formGroup.controls.totalAmount.value - allocated : 0 - allocated;
        this.unallocatedAmount.next(unallocatedAmount);
    };

    getDataRows = (): Array<any> => {
        return Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'accounting.wip.disbursements.columns.date',
            field: 'date',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.name',
            field: 'name',
            sortable: false,
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.case',
            field: 'case',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.staff',
            field: 'staff',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.disbursement',
            field: 'disbursement',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.foreignAmount',
            field: 'foreignAmount',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.margin',
            field: 'margin',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.value',
            field: 'value',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.discount',
            field: 'discount',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.quantity',
            field: 'quantity',
            template: true
        }, {
            title: 'accounting.wip.disbursements.columns.narrative',
            field: 'narrative',
            template: true
        }];

        return columns;
    };
}
