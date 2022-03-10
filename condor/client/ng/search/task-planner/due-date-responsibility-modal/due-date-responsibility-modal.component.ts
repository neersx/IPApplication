import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { AppContextService } from 'core/app-context.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { ReminderRequestType } from '../task-planner.data';

@Component({
  selector: 'ipx-due-date-responsibility-modal',
  templateUrl: './due-date-responsibility-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DueDateResponsibilityModalComponent implements OnInit {

  modalRef: BsModalRef;
  name: any;
  requestType: ReminderRequestType;
  picklistPlaceholder: string;

  @Output() private readonly saveClicked = new EventEmitter<any>();
  @ViewChild('dueDateRespForm', { static: true }) form: NgForm;

  constructor(bsModalRef: BsModalRef, private readonly cdr: ChangeDetectorRef, private readonly appContextService: AppContextService, private readonly ipxNotificationService: IpxNotificationService) {
    this.modalRef = bsModalRef;
  }

  ngOnInit(): void {
    this.picklistPlaceholder = this.requestType === ReminderRequestType.BulkAction ? null : 'taskPlanner.dueDateResponsibility.unassigned';
  }

  onClose(): void {
    this.modalRef.hide();
  }

  assignToMe(): void {
    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe((ctx: any) => {
        this.name = { displayName: ctx.user.displayName, key: ctx.user.nameId };
        this.form.form.markAsDirty();
      });
  }

  save(): void {

    if (this.requestType === ReminderRequestType.InlineTask || this.name) {
      this.saveClicked.emit(this.name);
      this.modalRef.hide();

      return;
    }

    const modal = this.ipxNotificationService.openConfirmationModal('taskPlanner.dueDateResponsibility.confirmTitle', 'taskPlanner.dueDateResponsibility.confirmMessage', 'taskPlanner.dueDateResponsibility.remove', 'Cancel');
    modal.content.confirmed$.subscribe(() => {
      this.saveClicked.emit(this.name);
      this.modalRef.hide();
    });
  }

  isDirty(): boolean {
    return this.requestType === ReminderRequestType.BulkAction || this.form.dirty;
  }

}
