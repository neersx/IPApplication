import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { take, takeUntil } from 'rxjs/operators';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { CaseDebtorService } from '../../../case-debtor.service';

@Component({
    selector: 'ipx-maintain-debtor-copies-to',
    templateUrl: './maintain-debtor-copies-to.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})

export class MaintainDebtorCopiesToComponent implements OnInit {
    @Input() debtorNameId: number;
    @Input() grid: any;
    @Input() isAdding: boolean;
    @Input() dataItem: any;
    @Input() rowIndex: number;
    @Input() reasonList: any;
    onClose$ = new Subject();
    formGroup: any;
    disableFields = true;
    disableReason = true;
    copyDebtors: any;
    copyNameKey: number;
    hasAddressChanged: boolean;
    hasContactNameChanged: boolean;
    @ViewChild('addressChangeReason', { static: false }) addressChangeReasonEl: any;
    @ViewChild('copyToName', { static: false }) copyToNameEl: any;

    get CopyToNameValue(): FormControl {
        return this.formGroup.get('CopyToNameValue') as FormControl;
    }
    get ContactName(): FormControl {
        return this.formGroup.get('ContactName') as FormControl;
    }
    get AddressChangeReasonId(): FormControl {
        return this.formGroup.get('AddressChangeReasonId') as FormControl;
    }
    get Address(): FormControl {
        return this.formGroup.get('Address') as FormControl;
    }

    constructor(private readonly service: CaseDebtorService,
        private readonly sbsModalRef: BsModalRef,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly fb: FormBuilder,
        private readonly shortcutsService: IpxShortcutsService,
        private readonly destroy$: IpxDestroy,
        readonly cdRef: ChangeDetectorRef) {
    }

    ngOnInit(): void {
        this.createFormGroup();
        this.copyNameKey = this.dataItem.CopyToNameId;
        this.disableFields = this.isAdding && !this.dataItem.CopyToNameId;
        this.disableReason = this.isAdding || !this.dataItem.AddressChangeReasonId;
        this.handleShortcuts();
    }

    onCopyToNameChange(event: any): void {
        if (event && event.key) {
            if (this.dataItem.status === rowStatus.Adding) {
                const data: any = _.filter(this.grid.wrapper.data, (row: any) => {
                    return row !== undefined;
                });
                const isExsiting = _.any(data, (row: any) => {
                    return row.CopyToNameId === event.key;
                });
                if (isExsiting) {
                    this.formGroup.controls.CopyToNameValue.setErrors({ duplicate: 'duplicate' });
                    this.formGroup.controls.CopyToNameValue.markAsDirty();
                    this.formGroup.controls.CopyToNameValue.markAsTouched();
                    if (this.copyToNameEl) {
                        this.copyToNameEl.el.nativeElement.querySelector('input').click();
                    }
                    this.clearAndDisableFields();
                    this.cdRef.markForCheck();

                    return;
                }
            }

            this.service.getDebtorCopiesToDetails(this.debtorNameId, event.key)
                .subscribe((res: any) => {
                    if (res) {
                        this.setFormData(res, event);
                    }
                    this.hasAddressChanged = false;
                    this.hasContactNameChanged = false;
                    this.disableFields = event ? false : true;
                });
        } else {
            this.clearAndDisableFields();
        }
    }

    clearAndDisableFields = () => {
        this.formGroup.controls.ContactName.reset();
        this.formGroup.controls.Address.reset();
        this.formGroup.controls.AddressChangeReasonId.reset();
        this.disableFields = true;
    };

    onAddressChange(event: any): void {
        if (event) {
            this.hasAddressChanged = true;
        }
        this.setAddressChangeReasonDisability();
    }

    setAddressChangeReasonDisability = () => {
        if (this.hasAddressChanged || this.hasContactNameChanged) {
            this.disableReason = false;
        } else {
            this.formGroup.controls.AddressChangeReasonId.reset();
        }
    };

    onContactNameChange(event: any): void {
        if (event) {
            this.hasContactNameChanged = true;
        }
        this.setAddressChangeReasonDisability();
    }

    setFormData(data: any, copyToNameData: any): any {
        this.formGroup.patchValue({
            CopyToNameValue: { key: copyToNameData.key, code: copyToNameData.code, displayName: data.CopyToName },
            CopyToNameId: copyToNameData.key,
            CopyToName: data.CopyToName,
            ContactName: data.ContactName,
            ContactNameId: data.ContactNameId,
            Address: data.Address,
            AddressId: data.AddressId,
            AddressChangeReasonId: data.AddressChangeReasonId
        });
        this.cdRef.markForCheck();
    }

    createFormGroup = (): FormGroup => {
        this.formGroup = this.fb.group({
            CopyToNameId: new FormControl(!this.dataItem.CopyToNameId ? null : this.dataItem.CopyToNameId),
            CopyToName: new FormControl(!this.dataItem.CopyToName ? null : this.dataItem.CopyToName),
            CopyToNameValue: new FormControl(!this.dataItem.CopyToNameId ? null : { key: this.dataItem.CopyToNameId, displayName: this.dataItem.CopyToName }, { validators: Validators.required }),
            ContactNameId: new FormControl(!this.dataItem.ContactNameId ? null : this.dataItem.ContactNameId),
            ContactName: new FormControl(!this.dataItem.ContactName ? null : this.dataItem.ContactName),
            AddressId: new FormControl(!this.dataItem.AddressId ? null : this.dataItem.AddressId),
            Address: new FormControl(!this.dataItem.Address ? null : this.dataItem.Address),
            AddressChangeReasonId: new FormControl(!this.dataItem.AddressChangeReasonId ? null : this.dataItem.AddressChangeReasonId)
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

    validateReason = (): boolean => {
        if ((this.hasAddressChanged || this.hasContactNameChanged) && !this.formGroup.controls.AddressChangeReasonId.value) {
            this.formGroup.controls.AddressChangeReasonId.markAsDirty();
            this.formGroup.controls.AddressChangeReasonId.markAsTouched();
            this.formGroup.controls.AddressChangeReasonId.setErrors({ required: true });
            if (this.addressChangeReasonEl) {
                this.addressChangeReasonEl.el.nativeElement.querySelector('select').click();
            }
            this.cdRef.markForCheck();

            return false;
        }

        return true;
    };

    apply = (): void => {
        if (!this.validateReason()) { return; }
        if (this.formGroup && this.formGroup.valid) {
            this.sbsModalRef.hide();
            this.onClose$.next({ success: true, formGroup: this.formGroup });
        }
    };

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
        if (this.dataItem.status === rowStatus.Adding && !this.dataItem.CopyToNameId) {
            this.grid.rowCancelHandler(this, this.rowIndex, this.dataItem);
        }
        this.formGroup.reset();
        this.onClose$.next(isDirty);
        this.sbsModalRef.hide();
    };
}