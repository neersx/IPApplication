import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { BulkUpdateReasonData, DropDownData } from 'search/case/bulk-update/bulk-update.data';
import { BulkPolicingService, BulkPolicingViewData } from './bulk-policing-service';

@Component({
    selector: 'app-bulk-policing-request',
    templateUrl: './bulk-policing-request.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class BulkPolicingRequestComponent implements OnInit {

    caseAction: any;
    reasonData: BulkUpdateReasonData;
    onClose: Subject<any>;
    textTypes: Array<DropDownData>;
    allowRichText: boolean;
    selectedCases: Array<number>;
    @ViewChild('f', { static: true }) ngForm: NgForm;
    constructor(
        private readonly bsModalRef: BsModalRef,
        private readonly bulkPolicingService: BulkPolicingService,
        private readonly cdRef: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.onClose = new Subject();
        this.reasonData = new BulkUpdateReasonData();
        this.bulkPolicingService.getBulkPolicingViewData().subscribe((viewData: BulkPolicingViewData) => {
            this.textTypes = viewData.textTypes;
            this.allowRichText = viewData.allowRichText;
            this.cdRef.markForCheck();
        });
    }

    close(): void {
        this.onClose.next(false);
        this.bsModalRef.hide();
    }

    submit = (): void => {
        if (!this.reasonData.notes || this.reasonData.notes.trim() === '' || this.reasonData.textType) {
            this.bulkPolicingService.sendBulkPolicingRequest(this.selectedCases, this.caseAction.code, this.reasonData)
            .subscribe(() => {
                this.onClose.next(true);
                this.bsModalRef.hide();
            });
        } else {
            this.reasonData.notes = '';
        }
    };

    reasonChange = () => {
        if (!this.reasonData.textType) {
            this.reasonData.notes = '';
        }
    };
}