import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-status',
  templateUrl: './status.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class StatusComponent extends CaseSearchTopicBaseComponent implements OnInit, TopicContract {
  topic: Topic;
  formData: any = {};
  viewData: any;
  isExternal: any;
  @ViewChild('caseSearchForm', { static: true }) form: NgForm;

  ngOnInit(): void {
    this.onInit();
  }

  updateStatusInputs = (source) => {
    if (source === 'pending' || source === 'registered' || source === 'dead') {
      if (!this.formData.isPending && !this.formData.isRegistered && !this.formData.isDead) {
        this.formData[source] = true;
        this.form.controls[source].setValue(true);
      } else {
        this.formData.caseStatus = null;
        this.formData.renewalStatus = null;
      }
    }
    this.cdRef.detectChanges();
  };

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;

    return {
      statusFlags: {
        isPending: formData.isPending ? 1 : 0,
        isRegistered: formData.isRegistered ? 1 : 0,
        isDead: formData.isDead ? 1 : 0
      },
      statusKey: this.casehelper.buildStringFilterFromTypeahead(formData.caseStatus, formData.caseStatusOperator),
      renewalStatusKey: this.casehelper.buildStringFilterFromTypeahead(formData.renewalStatus, formData.renewalStatusOperator)
    };
  };

  extendCaseStatus = (query) => {
    return this.extendStatusQuery(query, false);
  };

  extendRenewalStatus = (query) => {
    return this.extendStatusQuery(query, true);
  };

  extendStatusQuery = (query, isRenewal) => {
    return {...query,
      isRenewal,
      isPending: this.formData.isPending,
      isRegistered: this.formData.isRegistered,
      isDead: this.formData.isDead};
  };
}
