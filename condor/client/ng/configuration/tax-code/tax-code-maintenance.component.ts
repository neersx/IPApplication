import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { TaxCodes } from './tax-code.model';
import { TaxCodeService } from './tax-code.service';

@Component({
    selector: 'add-tax-codes',
    templateUrl: './tax-code-maintenance.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class TaxCodeMaintenanceComponent {
    formData = new TaxCodes();
    modalRef: BsModalRef;
    states: string;
    dataItem: any;
    @Output() readonly searchRecord: EventEmitter<any> = new EventEmitter();
    @ViewChild('addTaxCodes', { static: true }) ngForm: NgForm;

    constructor(private readonly taxCodeService: TaxCodeService, private readonly notificationService: NotificationService,
        private readonly ipxNotificationService: IpxNotificationService) { }

    save(): void {
        if (!this.validate()) {
            return;
        }

        this.taxCodeService.saveTaxCode(this.formData).subscribe(r => {
            if (r.result === 'success') {
                this.notificationService.success();
                this.searchRecord.emit({ runSearch: true, taxRateId: r.taxRateId });
            } else {
                const errors = r.errors;
                const error = _.find(errors, (er: any) => {
                    return er.field === 'taxCode';
                });
                const message = error.message;
                this.ipxNotificationService.openAlertModal('modal.unableToComplete', message, errors);
                this.ngForm.controls.taxCode.markAsTouched();
                this.ngForm.controls.taxCode.markAsDirty();
                this.ngForm.controls.taxCode.setErrors({ notunique: true });
            }
        });
    }

    validate = () => {
        return this.ngForm.valid;
    };

    disable = (): boolean => {
        return !this.ngForm.dirty || !this.ngForm.valid;
    };

    onClose(): void {
        if (this.ngForm.dirty) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();
            this.modalRef.content.confirmed$.subscribe(() => {
                this.searchRecord.emit({ runSearch: false });

            });
        } else {
            this.searchRecord.emit({ runSearch: false });
        }
    }
}