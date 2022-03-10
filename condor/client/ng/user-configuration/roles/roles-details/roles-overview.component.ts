import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, NgForm } from '@angular/forms';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { RoleSearchService } from '../role-search.service';
@Component({
  selector: 'ipx-roles-overview',
  templateUrl: './roles-overview.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RolesOverviewComponent implements OnInit, TopicContract {
  topic: Topic;
  formData: any = {};
  viewData: any;
  checkedValue = 1;
  @ViewChild('overViewForm', { static: true }) overViewForm: NgForm;
  constructor(public cdRef: ChangeDetectorRef, private readonly roleSearchService: RoleSearchService) { }

  ngOnInit(): void {
    if (this.topic.params && this.topic.params.viewData) {
      this.viewData = { ...this.topic.params.viewData };
      setTimeout(() => {
        this.cdRef.markForCheck();
      });
    }
    this.initTopicsData();
    Object.assign(this.topic, {
      getFormData: this.getFormData,
      isDirty: this.isDirty,
      isValid: this.isValid,
      setPristine: this.setPristine,
      clear: this.clear,
      revert: this.revert
    });
  }

  clear = (): void => {
    this.initTopicsData();
  };

  getFormData = (): any => {
    if (this.isValid()) {
      return { formData: { overviewDetails: this.formData } };
    }
  };

  isValid = (): boolean => {
    return this.overViewForm.valid;
  };

  isDirty = (): boolean => {
    return this.overViewForm.dirty;
  };

  setPristine = (): void => {
    _.each(this.overViewForm.controls, (c: AbstractControl) => {
      c.markAsPristine();
      c.markAsUntouched();
    });
  };

  revert = (): any => {
    this.setPristine();
    this.formData = {};
  };

  initTopicsData = () => {
    const roleDetails = this.roleSearchService.overviewDetails(this.viewData.roleId);
    roleDetails.subscribe(role => {
      this.formData = role;
      this.formData.roleId = this.viewData.roleId;
      this.roleSearchService._roleName$.next(this.formData.roleName);
      this.cdRef.markForCheck();
    });
  };
}