import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { CaseValidateCharacteristicsCombinationService } from 'portfolio/case/case-validate-characteristics-combination.service';
import { BehaviorSubject } from 'rxjs';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { CaseCharacteristics } from '../maintenance-model';
import { SanityCheckMaintenanceService } from '../sanity-check-maintenance.service';

@Component({
  selector: 'ipx-sanity-check-rule-case-characteristics',
  templateUrl: './case-characteristics.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SanityCheckRuleCaseCharacteristicsComponent implements TopicContract, OnInit {
  topic: Topic;
  view?: any;
  formData?: any;
  extendValidCombinationPickList: any;
  picklistValidCombination: any;
  appliesToOptions: Array<any>;
  isCaseCategoryDisabled = new BehaviorSubject(true);
  @ViewChild('frm', { static: true }) form: NgForm;

  constructor(private readonly cdr: ChangeDetectorRef, private readonly service: SanityCheckMaintenanceService, public cvs: CaseValidCombinationService, private readonly validatorService: CaseValidateCharacteristicsCombinationService) {
    this.picklistValidCombination = this.cvs.validCombinationDescriptionsMap;
    this.extendValidCombinationPickList = this.cvs.extendValidCombinationPickList;
    this.appliesToOptions = [{
      value: 1,
      label: 'sanityCheck.configurations.localOrForeignDropdown.localClients'
    }, {
      value: 0,
      label: 'sanityCheck.configurations.localOrForeignDropdown.foreignClients'
    }];
  }

  ngOnInit(): void {
    this.view = (this.topic.params?.viewData as CaseCharacteristics);
    this.formData = !!this.view ? { ...this.view } : {};
    this.topic.getDataChanges = this.getDataChanges;
    this.cvs.initFormData(this.formData);
    this.verifyCaseCategoryStatus();

    this.form.statusChanges.subscribe(() => {
      this.topic.hasChanges = this.form.dirty;
      const hasErrors = this.form.dirty && this.form.invalid;
      this.topic.setErrors(hasErrors);
      this.service.raiseStatus(this.topic.key, this.topic.hasChanges, hasErrors, this.form.valid);
    });
  }

  getDataChanges = (): any => {
    const r = {};
    const rawData = this.validatorService.build(this.form.value);

    r[this.topic.key] = { ...this.formData, ...rawData };

    return r;
  };

  verifyCaseCategoryStatus = () => {
    const isCaseTypeSelected = this.isCaseTypeSelected();
    if (!isCaseTypeSelected) {
      this.formData.caseCategory = null;
    }
    this.isCaseCategoryDisabled.next(!isCaseTypeSelected);
  };

  onCriteriaChange = _.debounce(() => {
    this.cdr.markForCheck();
    this.validatorService.validateCaseCharacteristics$(this.form.control, 'C').then(() => {
      this.verifyCaseCategoryStatus();
      _.each(['caseType', 'jurisdiction', 'propertyType', 'caseCategory', 'subType', 'basis'], (e) => {
        this.resetExclusion(this.formData[e], e + 'Exclude');
      });
    });
  }, 100);

  resetExclusion = (baseData: any, exclusion: any): void => {
    if (!baseData) {
      this.formData[exclusion] = null;
    }
  };

  private readonly isCaseTypeSelected = (): boolean => {
    if (!!this.formData.caseType && !this.formData.caseTypeExclude) {
      return true;
    }

    return false;
  };

  statusChanged = (isStatusDeadChanged: boolean) => {
    if (!!isStatusDeadChanged) {
      if (!!this.formData.statusIncludeDead) {
        this.formData.statusIncludePending = null;
        this.formData.statusIncludeRegistered = null;
      }
    } else {
      this.formData.statusIncludeDead = null;
    }

    this.cdr.markForCheck();
  };
}
