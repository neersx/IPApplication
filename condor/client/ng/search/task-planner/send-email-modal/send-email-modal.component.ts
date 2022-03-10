import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { WindowRef } from 'core/window-ref';
import { BsModalRef } from 'ngx-bootstrap/modal';
import * as _ from 'underscore';
import { TaskPlannerService } from '../task-planner.service';

@Component({
  selector: 'ipx-forward-reminder-modal',
  templateUrl: './send-email-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SendEmailModalComponent {

  modalRef: BsModalRef;
  names: Array<any>;
  namesWithEmail: Array<any>;
  namesWithoutEmail: Array<any>;
  warningMessageKey: string;
  warningMessageParams: any;

  @Output() private readonly sendClicked = new EventEmitter<Array<any>>();
  @ViewChild('sendEmail', { static: true }) form: NgForm;

  constructor(bsModalRef: BsModalRef) {
    this.modalRef = bsModalRef;
  }

  onClose(): void {
    this.modalRef.hide();
  }

  send(): void {
    this.sendClicked.emit(_.pluck(this.namesWithEmail, 'displayMainEmail'));
  }

  isValid(): boolean {
    return this.form.valid && this.namesWithEmail && this.namesWithEmail.length > 0;
  }

  showWarning(): boolean {
    if (!this.names) {
      this.namesWithEmail = [];

      return false;
    }

    this.namesWithEmail = _.filter(this.names, (name) => {
      return !_.isEmpty(name.displayMainEmail);
    });

    this.namesWithoutEmail = _.filter(this.names, (name) => {
      return _.isEmpty(name.displayMainEmail);
    });

    if (!this.namesWithoutEmail || this.namesWithoutEmail.length === 0) {
      return false;
    }
    this.buildWarningMessage();

    return true;
  }

  buildWarningMessage(): void {
    if (this.namesWithoutEmail.length === 1) {
      this.warningMessageKey = 'taskPlanner.sendEmail.warningMessageSingle';
      this.warningMessageParams = { name: this.namesWithoutEmail[0].displayName };
    } else {
      const displayNames = _.pluck(this.namesWithoutEmail, 'displayName');
      this.warningMessageKey = 'taskPlanner.sendEmail.warningMessageMultiple';
      this.warningMessageParams = {
        names: displayNames.slice(0, displayNames.length - 1).join('; '),
        name: displayNames[displayNames.length - 1]
      };
    }
  }

}
