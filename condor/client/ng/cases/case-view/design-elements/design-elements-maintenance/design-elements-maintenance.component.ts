import { AfterViewInit, ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { take } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { ValidationError } from 'shared/component/forms/validation-error';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { TagsErrorValidator } from 'shared/component/typeahead/ipx-typeahead/typeahead.config.provider';
import { DesignElementItems } from '../design-elements.model';
import { DesignElementsService } from '../design-elements.service';

@Component({
    selector: 'design-elements-maintenance',
    templateUrl: './design-elements-maintenance.component.html',
    styleUrls: ['../design-elements.styles.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DesignElementsMaintenanceComponent implements OnInit, AfterViewInit {

    @Input() isAdding: boolean;
    @Input() isAddAnother: boolean;
    @Input() grid: any;
    @Input() caseKey: number;
    @Input() dataItem: any;
    @Input() rowIndex: number;
    onClose$ = new Subject();
    dataType: any = dataTypeEnum;
    isDateDisabled = false;
    isAddAnotherChecked = false;
    formGroup: any;
    @ViewChild('firmElem', { static: false }) firmElem: any;
    @ViewChild('imageEl', { static: false }) imageEl: any;

    constructor(readonly service: DesignElementsService,
        private readonly notificationService: IpxNotificationService,
        private readonly sbsModalRef: BsModalRef, private readonly formBuilder: FormBuilder) { }

    ngOnInit(): void {
        this.createFormGroup(this.dataItem);
        this.isAddAnotherChecked = this.service.isAddAnotherChecked.getValue();
        this.onRenewChanged(this.dataItem.renew);
    }

    createFormGroup = (dataItem: DesignElementItems): FormGroup => {
        if (dataItem) {
            this.formGroup = this.formBuilder.group({
                firmElementCaseRef: new FormControl(dataItem.firmElementCaseRef, [Validators.required, Validators.maxLength(20)]),
                clientElementCaseRef: new FormControl(dataItem.clientElementCaseRef, [Validators.maxLength(254)]),
                elementOfficialNo: new FormControl(dataItem.elementOfficialNo, [Validators.maxLength(20)]),
                registrationNo: new FormControl(dataItem.registrationNo, [Validators.maxLength(36)]),
                noOfViews: new FormControl(dataItem.noOfViews),
                renew: (dataItem && dataItem.renew) ? new FormControl(dataItem.renew) : null,
                stopRenewDate: (dataItem && dataItem.stopRenewDate) ? new FormControl(new Date(dataItem.stopRenewDate)) : null,
                elementDescription: new FormControl(dataItem.elementDescription, [Validators.maxLength(254)]),
                images: [{ value: !dataItem ? null : dataItem.images, disabled: false }],
                sequence: new FormControl(dataItem.sequence),
                rowKey: new FormControl(dataItem.rowKey),
                status: new FormControl(dataItem.status)
            });

            return this.formGroup;
        }

        return this.formBuilder.group({});
    };

    get images(): AbstractControl {
        return this.formGroup.get('images');
    }

    ngAfterViewInit(): void {
        if (!this.isAddAnother) {
            this.formGroup.markAsPristine();
        }
    }

    apply = (): void => {
        if (this.formGroup.dirty && this.formGroup.status !== 'INVALID') {
            this.validate();
        }
    };

    validate = () => {
        const dataRows = Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
        const changedRows = [];
        dataRows.forEach((r) => {
            if (r && r.status !== null && this.grid.rowEditFormGroups && this.grid.rowEditFormGroups[r.rowKey]) {
                const value = this.grid.rowEditFormGroups[r.rowKey].value;
                changedRows.push(value);
            }
        });
        this.service.getValidationErrors(this.caseKey, this.formGroup.value, changedRows)
            .subscribe((errors: Array<ValidationError>) => {
                if (errors && errors.length > 0) {
                    errors.map((err) => {
                        if (err.field === 'firmElementCaseRef') {
                            this.formGroup.controls.firmElementCaseRef.setErrors({ duplicateDesignElement: 'duplicate' });
                            this.firmElem.el.nativeElement.querySelector('input').click();
                        }
                        if (err.field === 'images') {
                            const errorObj: TagsErrorValidator = {
                                validator: { duplicateElementImage: 'duplicate' },
                                keys: err.customData,
                                keysType: 'key'
                            };
                            this.formGroup.controls.images.setErrors({ duplicateElementImage: 'duplicate', errorObj });
                            this.imageEl.el.nativeElement.querySelector('input').click();
                        }
                    });
                } else {
                    this.formGroup.setErrors(null);
                    const formStatus = { success: true, formGroup: this.formGroup };
                    this.onClose$.next(formStatus);
                    this.sbsModalRef.hide();
                }
            });
    };

    onCheckChanged = (): void => {
        this.service.isAddAnotherChecked.next(this.isAddAnotherChecked);
    };

    onRenewChanged = (value: boolean): void => {
        if (value) {
            this.formGroup.controls.stopRenewDate.setValue('');
        }
        this.isDateDisabled = value;
    };

    cancel = (): void => {
        if (this.formGroup.dirty) {
            const modal = this.notificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.resetForm(false);
                });
        } else {
            this.resetForm(false);
        }
    };

    resetForm = (isDirty: boolean): void => {
        if (this.dataItem.status === rowStatus.Adding && !this.dataItem.firmElementCaseRef) {
            this.grid.rowCancelHandler(this, this.rowIndex, this.formGroup.value);
        }
        this.service.isAddAnotherChecked.next(false);
        this.formGroup.reset();
        const formStatus = { success: isDirty, formGroup: this.formGroup };
        this.onClose$.next(formStatus);
        this.sbsModalRef.hide();
    };
}
