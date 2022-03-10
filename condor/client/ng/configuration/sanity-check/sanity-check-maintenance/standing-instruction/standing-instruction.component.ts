import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { StandingInstruction } from '../maintenance-model';
import { SanityCheckMaintenanceService } from '../sanity-check-maintenance.service';

@Component({
  selector: 'ipx-sanity-check-rule-standing-instruction',
  templateUrl: './standing-instruction.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SanityCheckRuleStandingInstructionComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData?: TopicViewData;
  formData?: any;
  isInstructionTypeSelected = new BehaviorSubject(false);
  @ViewChild('frm', { static: true }) form: NgForm;
  characteristicsExtendQuery = this.characteristicsFor.bind(this);

  constructor(private readonly cdr: ChangeDetectorRef, private readonly service: SanityCheckMaintenanceService) {
  }

  ngOnInit(): void {
    this.topic.getDataChanges = this.getDataChanges;
    const viewData = (this.topic.params?.viewData as StandingInstruction);
    this.formData = !!viewData ? { ...viewData } : {};
    this.instructionTypeSelected(!!this.formData.instructionType);

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
      instructionType: this.formData?.instructionType?.code,
      characteristics: this.formData?.characteristic?.id
    };

    return r;
  };

  instructionTypeSelected(flag: boolean): void {
    if (!flag) {
      this.formData.characteristic = null;
    }
    this.isInstructionTypeSelected.next(flag);
  }

  private characteristicsFor(query: any): any {
    const selectedInstructionType = this.formData.instructionType;
    const extended = _.extend({}, query, {
      instructionTypeCode: selectedInstructionType ? selectedInstructionType.code : null
    });

    return extended;
  }
}