import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { DateService } from 'ajs-upgraded-providers/date-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { AdHocDate, BulkFinaliseRequestModel, FinaliseRequestModel } from './adhoc-date.model';
import { AdhocDateService } from './adhoc-date.service';

@Component({
    selector: 'finalise-adhoc-date',
    templateUrl: './finalise-adhoc-date.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class FinaliseAdHocDateComponent implements OnInit {
    form: FormGroup;
    finaliseData: AdHocDate;
    saveAdhocDetails = new FinaliseRequestModel();
    bulkAdhocDetails = new BulkFinaliseRequestModel();
    dateFormat: any;
    modalRef: BsModalRef;
    isLoading = false;
    @Output() private readonly finaliseClicked = new EventEmitter<boolean>();

    constructor(bsModalRef: BsModalRef, private readonly dateService: DateService,
        private readonly adHocDateService: AdhocDateService, private readonly dateHelper: DateHelper) {
        this.modalRef = bsModalRef;
    }

    ngOnInit(): void {
        this.dateFormat = this.dateService.dateFormat;
        this.form = new FormGroup({
            reason: new FormControl(this.finaliseData.resolveReason ? this.finaliseData.resolveReason : null),
            finalisedOn: new FormControl(this.finaliseData.dateOccurred ? this.dateHelper.convertForDatePicker(this.finaliseData.dateOccurred) : new Date(), [Validators.required])
        });
    }

    finalise(): void {
        if (this.form.valid) {
            if (this.finaliseData.isBulkUpdate) {
                this.bulkAdhocDetails.userCode = this.form.controls.reason.value;
                this.bulkAdhocDetails.dateOccured = this.dateHelper.toLocal(this.form.controls.finalisedOn.value);
                this.bulkAdhocDetails.selectedTaskPlannerRowKeys = this.finaliseData.selectedTaskPlannerRowKeys;
                this.bulkAdhocDetails.searchRequestParams = this.finaliseData.searchRequestParams;
                this.isLoading = true;
                this.adHocDateService.bulkFinalise(this.bulkAdhocDetails).subscribe(response => {
                    this.isLoading = false;
                    this.modalRef.hide();
                    this.finaliseClicked.emit(response);
                });
            } else {
                this.saveAdhocDetails.userCode = this.form.controls.reason.value;
                this.saveAdhocDetails.dateOccured = this.dateHelper.toLocal(this.form.controls.finalisedOn.value);
                this.saveAdhocDetails.alertId = this.finaliseData.alertId;
                this.saveAdhocDetails.taskPlannerRowKey = this.finaliseData.taskPlannerRowKey;
                this.isLoading = true;
                this.adHocDateService.finalise(this.saveAdhocDetails).subscribe(response => {
                    this.isLoading = false;
                    this.modalRef.hide();
                    this.finaliseClicked.emit(response);
                });
            }
        }
    }

    onClose(): void {
        this.modalRef.hide();
    }

    disableFinalise = (): boolean => {
        return !this.form.valid;
    };
}
