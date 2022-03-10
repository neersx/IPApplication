import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { AppContextService } from 'core/app-context.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { take } from 'rxjs/operators';

@Component({
  selector: 'ipx-forward-reminder-modal',
  templateUrl: './forward-reminder-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ForwardReminderModalComponent {

  modalRef: BsModalRef;
  names: Array<any>;

  @Output() private readonly saveClicked = new EventEmitter<Array<any>>();
  @ViewChild('forwardReminder', { static: true }) form: NgForm;

  constructor(bsModalRef: BsModalRef) {
    this.modalRef = bsModalRef;
  }

  onClose(): void {
    this.modalRef.hide();
  }

  save(): void {
    this.saveClicked.emit(this.names);
    this.modalRef.hide();
  }

  isValid(): boolean {
    return this.form.valid && this.names != null;
  }

}
