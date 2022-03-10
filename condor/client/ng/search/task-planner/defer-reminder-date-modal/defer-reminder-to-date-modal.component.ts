import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';

@Component({
  selector: 'ipx-defer-reminder-date-modal',
  templateUrl: './defer-reminder-to-date-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DeferReminderToDateModalComponent {

  modalRef: BsModalRef;
  enteredDate: Date;
  today = new Date();

  @Output() private readonly deferClicked = new EventEmitter<Date>();
  @ViewChild('reminderForm', { static: true }) form: NgForm;

  constructor(bsModalRef: BsModalRef, private readonly cdr: ChangeDetectorRef) {
    this.modalRef = bsModalRef;
  }

  onClose(): void {
    this.modalRef.hide();
  }

  deferReminder(): void {
    this.deferClicked.emit(this.enteredDate);
    this.modalRef.hide();
  }

  isValid(): boolean {
    return this.form.valid && this.enteredDate != null;
  }

}
