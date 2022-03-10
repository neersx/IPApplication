import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import { Other } from '../maintenance-model';
import { SanityCheckMaintenanceService } from '../sanity-check-maintenance.service';

@Component({
  selector: 'ipx-sanity-check-rule-other',
  templateUrl: './other.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SanityCheckRuleOtherComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData?: TopicViewData;
  matchType: string;
  formData?: any;
  isInstructionTypeSelected = new BehaviorSubject(false);
  @ViewChild('frm', { static: true }) form: NgForm;

  constructor(private readonly cdRef: ChangeDetectorRef, private readonly service: SanityCheckMaintenanceService) {
  }

  ngOnInit(): void {
    this.topic.getDataChanges = this.getDataChanges;
    const viewData = (this.topic.params?.viewData as Other);
    this.matchType = (this.topic.params as any)?.matchType;
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
      tableCode: this.formData?.tableColumn?.key
    };

    return r;
  };

  eventSet(): void {
    if (!this.formData.event) {
      this.formData.eventIncludeDue = false;
      this.formData.eventIncludeOccurred = false;
    }
    this.cdRef.markForCheck();
  }
}
