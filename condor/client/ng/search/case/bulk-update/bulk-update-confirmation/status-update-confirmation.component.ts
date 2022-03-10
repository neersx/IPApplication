import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import * as _ from 'underscore';
import { BulkUpdateService } from '../bulk-update.service';

@Component({
    selector: 'app-status-update-confirmation',
    templateUrl: './status-update-confirmation.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class StatusUpdateConfirmationComponent implements OnInit {

    formData: any;
    onClose: Subject<any>;
    confirmationPassword: string;
    @ViewChild('f', { static: true }) ngForm: NgForm;
    constructor(
        private readonly bsModalRef: BsModalRef,
        private readonly bulkUpdateService: BulkUpdateService,
        private readonly changeDetectorRef: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.onClose = new Subject();
    }

    close(): void {
        this.onClose.next(false);
        this.bsModalRef.hide();
    }

    submit = (): boolean => {
        if (!this.confirmationPassword || this.confirmationPassword === '') {
            return false;
        }

        this.bulkUpdateService.checkStatusPassword(this.confirmationPassword).subscribe((response) => {
            if (!response) {
                const control = this.ngForm.controls.statusConfirmation;
                if (control) {
                    control.markAsTouched();
                    control.setErrors({ 'bulkUpdate.incorrectPassword': true });
                }

                return false;
            }
            this.changeDetectorRef.markForCheck();

            this.onClose.next(this.confirmationPassword);
            this.bsModalRef.hide();

            return true;
        });
    };

}