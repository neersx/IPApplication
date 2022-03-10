import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { BillingService } from 'accounting/billing/billing-service';
import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { TypeOfDetails } from 'accounting/billing/billing.model';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { take, takeUntil } from 'rxjs/operators';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { CaseDebtorService } from '../../case-debtor.service';

@Component({
    selector: 'ipx-add-debtors',
    templateUrl: './add-debtors.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})

export class AddDebtorsComponent implements OnInit {
    @Input() grid: any;
    @Input() request: any;
    @Input() openItemRequest: any;
    @Input() isAdding: boolean;
    @Input() dataItem: any;
    @Input() rowIndex: number;
    @ViewChild('reasonElement', { static: false }) reasonElement: any;
    onClose$ = new Subject();
    formGroup: any;
    disableFields = true;
    disableReason = true;
    debtorKey: number;
    debtorResponseData: any = {};
    sendToNameAttentionExtendQuery: any;
    sendToNameAddressExtendQuery: any;
    reasonList: any;

    get FormattedNameWithCode(): FormControl {
        return this.formGroup.get('FormattedNameWithCode') as FormControl;
    }
    get ReferenceNo(): FormControl {
        return this.formGroup.get('ReferenceNo') as FormControl;
    }
    get AttentionName(): FormControl {
        return this.formGroup.get('AttentionName') as FormControl;
    }
    get Reason(): FormControl {
        return this.formGroup.get('Reason') as FormControl;
    }

    get Address(): FormControl {
        return this.formGroup.get('Address') as FormControl;
    }

    get BillPercentage(): FormControl {
        return this.formGroup.get('BillPercentage') as FormControl;
    }

    get Currency(): FormControl {
        return this.formGroup.get('Currency') as FormControl;
    }

    get TotalCredits(): FormControl {
        return this.formGroup.get('TotalCredits') as FormControl;
    }

    get TotalWip(): FormControl {
        return this.formGroup.get('TotalWip') as FormControl;
    }

    constructor(private readonly service: CaseDebtorService,
        private readonly billingStepsService: BillingStepsPersistanceService,
        private readonly sbsModalRef: BsModalRef,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly fb: FormBuilder,
        private readonly shortcutsService: IpxShortcutsService,
        private readonly destroy$: IpxDestroy,
        readonly cdRef: ChangeDetectorRef,
        private readonly billingService: BillingService) {
        this.sendToNameAttentionExtendQuery = this.sendToNameAttention.bind(this);
        this.sendToNameAddressExtendQuery = this.sendToNameAddress.bind(this);
        this.reasonList = this.billingService.reasonList$.getValue();
    }

    ngOnInit(): void {
        this.createFormGroup();
        this.disableFields = this.isAdding;
        this.handleShortcuts();
    }

    onDebtorChange(event: any): void {
        if (event && event.key) {
            const data = this.billingStepsService.getStepData(1);
            this.debtorKey = event.key;
            this.service.getDebtors(TypeOfDetails.Details, null, null, null, data.stepData.currentAction ? data.stepData.currentAction.code : null, data.stepData.entity, data.stepData.raisedBy.key, event.key, null, data.stepData.useRenewalDebtor, data.stepData.itemDate)
                .subscribe((res: any) => {
                    if (res.DebtorList && res.DebtorList.length > 0) {
                        this.setFormData(res.DebtorList[0], event);
                        this.debtorResponseData = res.DebtorList[0];
                        if (!res.DebtorList[0].IsClient) {
                            this.ipxNotificationService.openAlertModal(null, 'accounting.billing.step1.addDebtors.BI25');
                            this.formGroup.controls.FormattedNameWithCode.reset();
                            this.disableFields = true;
                        }
                    }
                    this.disableFields = event ? false : true;
                });
        } else {
            this.formGroup.controls.ReferenceNo.reset();
            this.formGroup.controls.AttentionName.reset();
            this.formGroup.controls.Address.reset();
            this.formGroup.controls.Reason.reset();
            this.debtorResponseData = {};
            this.disableFields = true;
        }
    }

    onAddressChange(event: any): void {
        this.toggleReason(event);
    }

    onAttentionChange(event: any): void {
        this.toggleReason(event);
    }

    onReferenceChange(event: any): void {
        this.toggleReason(event);
    }

    toggleReason(event: any): void {
        if (event) {
            this.disableReason = false;

            return;
        }
    }

    validateRequiredFiled(): boolean {
        if (!this.disableReason && (this.reasonList && this.reasonList.length > 0) && !this.formGroup.controls.Reason.value) {
            this.formGroup.controls.Reason.markAsTouched();
            this.formGroup.controls.Reason.markAsDirty();
            this.formGroup.controls.Reason.setErrors({ required: true });
            this.reasonElement.el.nativeElement.querySelector('select').click();
            this.cdRef.detectChanges();

            return false;
        }

        return true;
    }

    sendToNameAttention(query: any): void {
        const extended = _.extend({}, query, {
            associatedNameId: this.debtorKey,
            entityTypes: JSON.stringify({
                isIndividual: 'true'
            })
        });

        return extended;
    }

    private sendToNameAddress(query: any): void {
        const extended = _.extend({}, query, {
            associatedNameId: this.debtorKey
        });

        return extended;
    }

    setFormData(data: any, debtorData: any): any {
        this.formGroup.setValue({
            DebtorCheckbox: new FormControl(null),
            DebtorRestriction: data.DebtorRestriction,
            FormattedNameWithCode: { key: debtorData.key, code: debtorData.code, displayName: data.FormattedNameWithCode },
            ReferenceNo: data.ReferenceNo,
            AttentionName: data.AttentionName,
            Address: data.Address,
            Reason: data.Reason ?? null,
            BillPercentage: data.BillPercentage,
            Currency: data.Currency,
            TotalCredits: data.TotalCredits,
            TotalWip: data.TotalWip
        });
        this.cdRef.markForCheck();
    }

    createFormGroup = (): FormGroup => {
        if (this.dataItem && this.dataItem.Reason) {
            const debtorReason: any = _.filter(this.billingService.reasonList$.getValue(), (item: any) => {
                return item.Name === this.dataItem.Reason;
            });
            this.dataItem.Reason = debtorReason && debtorReason.length > 0 ? debtorReason[0].Id : null;
        }

        this.formGroup = this.fb.group({
            DebtorCheckbox: new FormControl(null),
            DebtorRestriction: new FormControl(this.isAdding ? null : this.dataItem.DebtorRestriction),
            FormattedNameWithCode: new FormControl(this.isAdding ? null : { key: this.dataItem.NameId, displayName: this.dataItem.FormattedNameWithCode }, { validators: Validators.required }),
            ReferenceNo: new FormControl(this.isAdding ? null : this.dataItem.ReferenceNo),
            Reason: new FormControl(this.isAdding || !this.dataItem.Reason ? null : this.dataItem.Reason),
            Address: new FormControl(this.isAdding ? null : this.dataItem.Address),
            AttentionName: new FormControl(this.isAdding ? null : this.dataItem.AttentionName),
            BillPercentage: new FormControl(this.isAdding ? null : this.dataItem.BillPercentage),
            Currency: new FormControl(this.isAdding ? null : this.dataItem.Currency),
            TotalCredits: new FormControl(this.isAdding ? null : this.dataItem.TotalCredits),
            TotalWip: new FormControl(this.isAdding ? null : this.dataItem.TotalWip)
        });

        return this.formGroup;
    };

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.SAVE, (): void => { this.apply(); }],
            [RegisterableShortcuts.REVERT, (): void => { this.cancel(); }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    apply(): any {
        const validForm = this.validateRequiredFiled();
        if (!validForm) {
            return;
        }
        if (this.formGroup && this.formGroup.valid) {
            if (this.formGroup.controls.Reason.value) {
                const debtorReason: any = _.filter(this.billingService.reasonList$.getValue(), (item: any) => {
                    return item.Id === this.formGroup.controls.Reason.value;
                });
                this.formGroup.value.Reason = debtorReason && debtorReason.length > 0 ? debtorReason[0].Name : null;
            }
            this.sbsModalRef.hide();
            this.onClose$.next({ success: true, formGroup: this.formGroup, debtorResponse: this.debtorResponseData });
        }
    }

    cancel = (): void => {
        if (this.formGroup && this.formGroup.dirty) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.resetForm(true);
                });
        } else {
            this.resetForm(false);
            this.sbsModalRef.hide();
        }
    };

    resetForm = (isDirty: boolean): void => {
        if (this.dataItem.status === rowStatus.Adding) {
            this.grid.rowCancelHandler(this, this.rowIndex, this.dataItem);
        }
        this.formGroup.reset();
        this.onClose$.next(isDirty);
        this.sbsModalRef.hide();
    };
}