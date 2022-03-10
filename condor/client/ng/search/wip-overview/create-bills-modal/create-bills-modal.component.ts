import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { AppContextService } from 'core/app-context.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { BillPreparationData } from '../wip-overview.data';
import { WipOverviewService } from '../wip-overview.service';

@Component({
  selector: 'ipx-create-bills-modal',
  templateUrl: './create-bills-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CreateBillsModalComponent implements OnInit {

  modalRef: BsModalRef;
  selectedItems: Array<any>;
  entities: Array<any>;
  formData: BillPreparationData;

  @Output() private readonly proceedClicked = new EventEmitter<BillPreparationData>();
  @ViewChild('createBills', { static: true }) form: NgForm;

  constructor(bsModalRef: BsModalRef,
    private readonly appContextService: AppContextService,
    private readonly wipOverviewService: WipOverviewService,
    private readonly notificationService: IpxNotificationService,
    private readonly dateHelper: DateHelper) {
    this.modalRef = bsModalRef;
    this.formData = new BillPreparationData();
  }

  ngOnInit(): void {
    const wipDefault = this.selectedItems[0];
    const entity = this.entities ? this.entities.find((item) => { return item.isDefault; }) : null;
    this.formData.entityId = wipDefault.entityId == null && entity ? entity.entityKey : wipDefault.entityId;
    this.formData.includeNonRenewal = _.any(this.selectedItems, (r) => r.isNonRenewalWip != null) ? wipDefault.isNonRenewalWip : true;
    this.formData.includeRenewal = _.any(this.selectedItems, (r) => r.isRenewalWip != null) ? wipDefault.isRenewalWip : true;
    this.formData.useRenewalDebtor = _.any(this.selectedItems, (r) => r.isUseRenewalDebtor != null) ? wipDefault.isUseRenewalDebtor : true;
    this.formData.fromDate = wipDefault.fromItemDate ? this.dateHelper.convertForDatePicker(wipDefault.fromItemDate) : null;
    this.formData.toDate = wipDefault.toItemDate ? this.dateHelper.convertForDatePicker(wipDefault.toItemDate) : null;
    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe((ctx: any) => {
        this.formData.raisedBy = { displayName: ctx.user.displayName, key: ctx.user.nameId };
        this.form.form.markAsDirty();
      });
  }

  onClose(): void {
    this.modalRef.hide();
  }

  proceed(): void {
    this.wipOverviewService.isEntityRestrictedByCurrency(this.formData.entityId).subscribe((response) => {
      if (response) {
        this.notificationService.openAlertModal('modal.unableToComplete', 'wipOverviewSearch.createBills.validationErrors.restrictedByCurrency', null, 'button.ok');
      } else {
        this.modalRef.hide();
        this.proceedClicked.emit(this.formData);
      }
    });
  }

  isValid(): boolean {
    return this.form.valid;
  }

}
