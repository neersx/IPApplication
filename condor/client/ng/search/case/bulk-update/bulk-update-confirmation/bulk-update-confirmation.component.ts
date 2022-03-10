import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { CommonUtilityService } from 'core/common.utility.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import * as _ from 'underscore';
import { BulkUpdateReasonData, DropDownData } from '../bulk-update.data';
import { BulkUpdateService } from '../bulk-update.service';

@Component({
  selector: 'app-bulk-update-confirmation',
  templateUrl: './bulk-update-confirmation.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BulkUpdateConfirmationComponent implements OnInit {

  formData: any;
  reasonData: BulkUpdateReasonData;
  onClose: Subject<any>;
  textTypes: Array<DropDownData>;
  selectedCaseCount: number;
  removeItemCount: number;
  replaceItemCount: number;
  removeInfoMessage: string;
  replaceInfoMessage: string;
  hasCaseText: boolean;
  caseTextMessage: string;
  hasFileLocation: boolean;
  hasCaseNameReference: boolean;
  caseNameReferenceMessage: string;
  fileLocationMessage: string;
  replaceItems: any;
  removeItems: any;
  hasRestrictedStatus: boolean;
  selectedCases: Array<number>;
  restrictedStatusMessage: string;
  allowRichText: boolean;
  @ViewChild('f', { static: true }) ngForm: NgForm;
  constructor(
    private readonly bsModalRef: BsModalRef,
    private readonly translate: TranslateService,
    private readonly bulkUpdateService: BulkUpdateService,
    private readonly changeDetectorRef: ChangeDetectorRef,
    private readonly commonService: CommonUtilityService) { }

  ngOnInit(): void {
    this.onClose = new Subject();
    this.reasonData = new BulkUpdateReasonData();
    this.hasCaseText = this.formData.caseText && this.formData.caseText.textType;
    this.hasFileLocation = this.formData.fileLocation && this.formData.fileLocation.value;
    this.hasCaseNameReference = this.formData.caseNameReference && this.formData.caseNameReference.value;

    this.removeItems = _.pick(this.formData, (data: any, key: any) => {
      return data.toRemove && key !== 'caseText' && key !== 'fileLocation' && key !== 'caseNameReference';
    });

    this.replaceItems = _.pick(this.formData, (data: any, key: any) => {
      return !data.toRemove && key !== 'caseText' && key !== 'fileLocation' && key !== 'caseNameReference';
    });

    this.removeItemCount = _.size(this.removeItems);
    this.replaceItemCount = _.size(this.replaceItems);

    const caseOrCasesLabel: string = this.selectedCaseCount === 1 ? this.translate.instant('bulkUpdate.case') : this.translate.instant('bulkUpdate.cases');

    this.removeInfoMessage = this.commonService.formatString('{0} {1} {2}:',
      (this.removeItemCount === 1 ? this.translate.instant('bulkUpdate.removeMessageForSingle') : this.translate.instant('bulkUpdate.removeMessageForMultiple')),
      this.selectedCaseCount.toString(),
      caseOrCasesLabel
    );

    this.replaceInfoMessage = this.commonService.formatString('{0} {1} {2}:',
      (this.replaceItemCount === 1 ? this.translate.instant('bulkUpdate.replaceMessageForSingle') : this.translate.instant('bulkUpdate.replaceMessageForMultiple')),
      this.selectedCaseCount.toString(),
      caseOrCasesLabel
    );

    if (this.hasCaseText) {
      this.caseTextMessage = this.formData.caseText.toRemove ?
        this.translate.instant('bulkUpdate.caseTextUpdate.removeText') :
        this.formData.caseText.canAppend ? this.translate.instant('bulkUpdate.caseTextUpdate.appendText') :
          this.translate.instant('bulkUpdate.caseTextUpdate.replaceText');
      this.caseTextMessage = this.commonService.formatString('{0} {1} {2}.', this.caseTextMessage, this.selectedCaseCount.toString(), caseOrCasesLabel);
    }
    if (this.hasFileLocation) {
      this.fileLocationMessage = this.commonService.formatString('{0} {1} {2}.', (this.formData.fileLocation.toRemove ? this.translate.instant('bulkUpdate.fileLocationUpdate.removeText') : this.translate.instant('bulkUpdate.fileLocationUpdate.updateText')), this.selectedCaseCount.toString(), caseOrCasesLabel);
    }
    if (this.hasCaseNameReference) {
      this.caseNameReferenceMessage = this.commonService.formatString('{0} {1} {2}.', (this.formData.caseNameReference.toRemove ? this.translate.instant('bulkUpdate.caseNameReferenceUpdate.removeReference') : this.translate.instant('bulkUpdate.caseNameReferenceUpdate.updateReference')), this.selectedCaseCount.toString(), caseOrCasesLabel);
    }
    if (this.formData.caseStatus || this.formData.renewalStatus) {
      const status = this.formData.caseStatus != null ? this.formData.caseStatus : this.formData.renewalStatus;
      if (status.statusCode !== '') {
        this.bulkUpdateService.hasRestrictedCasesForStatus(this.selectedCases, status.statusCode).subscribe((response) => {
          this.hasRestrictedStatus = response;
          const statusType = status.isRenewal ? 'bulkUpdate.caseStatusUpdate.renewalStatus' : 'bulkUpdate.caseStatusUpdate.caseStatus';
          this.restrictedStatusMessage = this.commonService.formatString(this.translate.instant('bulkUpdate.caseStatusUpdate.restrictedStatus'), this.translate.instant(statusType));
          this.changeDetectorRef.markForCheck();
        });
      }
    }
  }

  close(): void {
    this.onClose.next(false);
    this.bsModalRef.hide();
  }

  submit = (): boolean => {
    let isValid = false;
    if (!this.reasonData.notes || this.reasonData.notes.trim() === '' || this.reasonData.textType) {
      this.onClose.next(this.reasonData);
      this.bsModalRef.hide();
      isValid = true;
    } else {
      this.reasonData.notes = '';
    }

    return isValid;
  };

  reasonChange = () => {

    if (!this.reasonData.textType) {
      this.reasonData.notes = '';
    }
    if (this.hasCaseText && this.formData.caseText.textType === this.reasonData.textType) {
      const control = this.ngForm.controls.textType;
      if (control) {
        control.markAsTouched();
        control.setErrors({ 'bulkUpdate.sameTextTypeErrorMessage': true });
      }
    }
  };

  asIsOrder = () => {
    return 1;
  };

  trackByFn = (index: number) => {
    return index;
  };

}