import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import { EventModel, Other } from '../maintenance-model';
import { SanityCheckMaintenanceService } from '../sanity-check-maintenance.service';

@Component({
  selector: 'ipx-sanity-check-rule-event',
  templateUrl: './event.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SanityCheckRuleEventComponent implements TopicContract, OnInit {
  topic: Topic;
  formData?: any;
  isInstructionTypeSelected = new BehaviorSubject(false);
  @ViewChild('frm', { static: true }) form: NgForm;

  constructor(private readonly cdRef: ChangeDetectorRef, private readonly service: SanityCheckMaintenanceService) {
  }

  ngOnInit(): void {
    this.topic.getDataChanges = this.getDataChanges;
    const viewData = (this.topic.params?.viewData as EventModel);
    this.formData = !!viewData ? { ...viewData } : {};

    this.form.statusChanges.subscribe(() => {
      this.topic.hasChanges = this.form.dirty;
      const hasErrors = this.form.dirty && this.form.invalid;
      this.topic.setErrors(hasErrors);
      this.service.raiseStatus(this.topic.key, this.topic.hasChanges, hasErrors, this.form.valid);
    });
  }

  getDataChanges = (): any => {
    const r = {};

    r[this.topic.key] = {
      eventNo: this.formData?.event?.key,
      includeDue: this.formData?.eventIncludeDue,
      includeOccurred: this.formData?.eventIncludeOccurred
    };

    return r;
  };

  eventSet(): void {
    if (!this.formData.event) {
      this.formData.eventIncludeDue = null;
      this.formData.eventIncludeOccurred = null;
    }
    this.cdRef.markForCheck();
  }
}
