import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import { CaseName } from '../maintenance-model';
import { SanityCheckMaintenanceService } from '../sanity-check-maintenance.service';

@Component({
  selector: 'ipx-sanity-check-rule-app-case-name',
  templateUrl: './case-name.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SanityCheckRuleCaseNameComponent implements TopicContract, OnInit {
  topic: Topic;
  view?: any;
  formData?: any;
  @ViewChild('frm', { static: true }) form: NgForm;

  constructor(private readonly cdr: ChangeDetectorRef, private readonly service: SanityCheckMaintenanceService) {
  }

  ngOnInit(): void {
    this.topic.getDataChanges = this.getDataChanges;
    this.view = (this.topic.params?.viewData as CaseName);
    this.formData = !!this.view ? { ...this.view } : { };

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
      nameGroup: this.formData?.nameGroup?.key,
      name: this.formData?.name?.key,
      nameType: this.formData?.nameType?.code
    };

    return r;
  };

  markForCheck = (): any => {
    this.cdr.markForCheck();
  };
}