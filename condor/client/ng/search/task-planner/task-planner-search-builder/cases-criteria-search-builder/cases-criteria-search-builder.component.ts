import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { KnownNameTypes } from 'names/knownnametypes';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { NameFilteredPicklistScope } from 'search/case/case-search-topics/name-filtered-picklist-scope';
import { SearchOperator } from 'search/common/search-operators';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { CasesCriteriaSearchBuilder } from '../search-builder.data';

@Component({
  selector: 'app-general-search-builder',
  templateUrl: './cases-criteria-search-builder.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CasesCriteriaSearchBuilderComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData: any;
  formData: CasesCriteriaSearchBuilder;
  formDataForVC = { caseType: {}, jurisdiction: {}, propertyType: {}, caseCategory: {} };
  searchOperator: any = SearchOperator;
  numberTypes: Array<any>;
  nameTypes: Array<any>;
  validCombinationDescriptionsMap: any;
  extendValidCombinationPickList: any;
  disabledCaseCategory = true;
  instructorPickListExternalScope: NameFilteredPicklistScope;
  ownerPickListExternalScope: NameFilteredPicklistScope;
  namePickListExternalScope: NameFilteredPicklistScope;

  @ViewChild('casesCriteriaForm', { static: true }) casesCriteriaForm: NgForm;
  constructor(private readonly cdr: ChangeDetectorRef,
    private readonly vcService: CaseValidCombinationService,
    private readonly knownNameTypes: KnownNameTypes,
    private readonly translate: TranslateService) {
    this.validCombinationDescriptionsMap =
      vcService.validCombinationDescriptionsMap;
    this.extendValidCombinationPickList =
      vcService.extendValidCombinationPickList;
    this.initFormData();
    this.vcService.initFormData(this.formDataForVC);
  }

  ngOnInit(): void {
    this.viewData = this.topic.params.viewData;
    this.numberTypes = this.viewData.numberTypes;
    this.nameTypes = this.viewData.nameTypes;
    if (this.viewData && this.viewData.formData && this.viewData.formData.cases) {
      this.formData = this.viewData.formData.cases;
      this.changeCaseType();
    }
    this.initTopicsData();
    Object.assign(this.topic, {
      getFormData: this.getFormData,
      clear: this.clear,
      isValid: this.isValid,
      isDirty: this.isDirty,
      setPristine: this.setPristine
    });
  }

  initTopicsData = () => {
    this.instructorPickListExternalScope = new NameFilteredPicklistScope(
      this.knownNameTypes.Instructor,
      this.translate.instant('picklist.instructor'),
      this.viewData.showCeasedNames
    );
    this.ownerPickListExternalScope = new NameFilteredPicklistScope(
      this.knownNameTypes.Owner,
      this.translate.instant('picklist.owner'),
      this.viewData.showCeasedNames
    );
    this.namePickListExternalScope = new NameFilteredPicklistScope();
  };

  namesTypeChanged(): any {
    if (this.formData.otherNameTypes.type != null) {
      this.namePickListExternalScope.filterNameType = this.formData.otherNameTypes.type;
      const nameType = _.find(this.nameTypes, (n: any) => {
        return n.key === this.formData.otherNameTypes.type;
      });
      this.namePickListExternalScope.nameTypeDescription = nameType ?
        nameType.value :
        null;
    } else {
      this.namePickListExternalScope.filterNameType = null;
      this.namePickListExternalScope.nameTypeDescription = null;
    }
    this.cdr.detectChanges();
  }

  clear = (): void => {
    this.initFormData();
    this.vcService.initFormData(this.formDataForVC);
    this.cdr.markForCheck();
  };

  isValid = (): boolean => {
    return this.casesCriteriaForm.valid;
  };

  isDirty = (): boolean => {
    return this.casesCriteriaForm.dirty;
  };

  setPristine = (): void => {
    _.each(this.casesCriteriaForm.controls, (c: AbstractControl) => {
      c.markAsPristine();
      c.markAsUntouched();
    });
  };

  changeCaseType = () => {
    if (!this.formData.caseType.value || this.formData.caseType.value.length === 0 || this.formData.caseType.value.length > 1) {
      this.formData.caseCategory.value = null;
      this.formData.caseCategory.operator = SearchOperator.equalTo;
      this.disabledCaseCategory = true;
    } else {
      this.disabledCaseCategory = false;
    }
    this.updateVCFormData();
    this.cdr.markForCheck();
  };

  getFormData = (): any => {
    const searchRequest: any = {};
    if (this.casesCriteriaForm.valid) {

      if (this.formData.caseReference.operator === SearchOperator.equalTo || this.formData.caseReference.operator === SearchOperator.notEqualTo) {
        searchRequest.caseKeys = this.getSearchElement('caseReference', 'key');
      } else {
        searchRequest.caseReference = this.getSearchElement('caseReference', 'key');
      }

      searchRequest.officialNumber = this.formData.officialNumber.value ?
        {
          operator: this.formData.officialNumber.operator,
          typeKey: this.formData.officialNumber.type,
          useRelatedCase: 0,
          useCurrent: 0,
          number: { value: this.formData.officialNumber.value }
        } : null;

      searchRequest.familyKeyList = this.formData.caseFamily.operator === SearchOperator.exists || this.formData.caseFamily.operator === SearchOperator.notExists ?
        { operator: this.formData.caseFamily.operator } : this.formData.caseFamily.value ?
          {
            operator: this.formData.caseFamily.operator,
            familyKey: this.formData.caseFamily.value.map((n: any) => ({ value: n.key }))
          } : null;

      searchRequest.countryKeys = this.getSearchElement('jurisdiction', 'key');
      searchRequest.caseList = this.getSearchElementFromObject('caseList', 'key');
      searchRequest.officeKeys = this.getSearchElement('caseOffice', 'key');
      searchRequest.caseTypeKeys = this.getSearchElement('caseType', 'code');
      searchRequest.propertyTypeKeys = this.getSearchElement('propertyType', 'code');
      searchRequest.categoryKey = this.getSearchElement('caseCategory', 'code');
      searchRequest.subTypeKey = this.getSearchElementFromObject('subType', 'code');
      searchRequest.basisKey = this.getSearchElementFromObject('basis', 'code');

      searchRequest.instructorKeys = this.getSearchElement('instructor', 'key');
      searchRequest.ownerKeys = this.getSearchElement('owner', 'key');
      searchRequest.otherNameTypeKeys = this.getSearchElement('otherNameTypes', 'key');
      if (searchRequest.otherNameTypeKeys) {
        searchRequest.otherNameTypeKeys.type = this.formData.otherNameTypes.type;
      }
      searchRequest.statusKey = this.getSearchElementFromObject('caseStatus', 'key');
      searchRequest.renewalStatusKey = this.getSearchElementFromObject('renewalStatus', 'key');
      searchRequest.statusFlags = {
        isPending: this.formData.isPending ? 1 : 0,
        isRegistered: this.formData.isRegistered ? 1 : 0,
        isDead: this.formData.isDead ? 1 : 0,
        checkDeadCaseRestriction: 1
      };

      return { searchRequest, formData: { cases: this.formData } };
    }
  };

  private readonly getSearchElement = (itemName: string, valueProperty: string): any => {
    const element = this.formData[itemName];
    const data = element.operator === SearchOperator.exists || element.operator === SearchOperator.notExists ? { operator: element.operator } :
      element.value ? {
        operator: element.operator, value: Array.isArray(element.value) ? _.pluck(element.value, valueProperty).join(',') : element.value
      } : null;

    return data;
  };

  private readonly getSearchElementFromObject = (itemName: string, valueProperty: string): any => {
    const element = this.formData[itemName];
    const data = element.operator === SearchOperator.exists || element.operator === SearchOperator.notExists ? { operator: element.operator } :
      element.value ? { operator: element.operator, value: element.value[valueProperty] } : null;

    return data;
  };

  changeOperator = (field: string): void => {
    const data = this.formData[field];
    // tslint:disable-next-line: prefer-conditional-expression
    if (data.operator === SearchOperator.equalTo || data.operator === SearchOperator.notEqualTo) {
      data.value = Array.isArray(data.value) ? data.value : null;
    } else if (data.operator === SearchOperator.startsWith || data.operator === SearchOperator.endsWith || data.operator === SearchOperator.contains) {
      data.value = Array.isArray(data.value) ? null : data.value;
    } else {
      data.value = null;
    }
  };

  initFormData(): void {
    this.formData = {
      basis: { operator: SearchOperator.equalTo },
      caseCategory: { operator: SearchOperator.equalTo },
      caseFamily: { operator: SearchOperator.equalTo },
      caseList: { operator: SearchOperator.equalTo },
      caseOffice: { operator: SearchOperator.equalTo },
      caseReference: { operator: SearchOperator.startsWith },
      caseType: { operator: SearchOperator.equalTo },
      jurisdiction: { operator: SearchOperator.equalTo },
      officialNumber: { operator: SearchOperator.equalTo, type: '' },
      propertyType: { operator: SearchOperator.equalTo },
      subType: { operator: SearchOperator.equalTo },
      caseStatus: { operator: SearchOperator.equalTo },
      renewalStatus: { operator: SearchOperator.equalTo },
      instructor: { operator: SearchOperator.equalTo },
      owner: { operator: SearchOperator.equalTo },
      otherNameTypes: { operator: SearchOperator.equalTo, type: '' },
      isRegistered: true,
      isPending: true,
      isDead: false
    };
    this.disabledCaseCategory = true;
    this.updateVCFormData();
  }

  updateVCFormData(): void {
    this.formDataForVC.caseType = this.formData.caseType.value;
    this.formDataForVC.jurisdiction = this.formData.jurisdiction.value;
    this.formDataForVC.propertyType = this.formData.propertyType.value;
    this.formDataForVC.caseCategory = this.formData.caseCategory.value;
  }

  extendCaseStatus = (query) => {
    return this.extendStatusQuery(query, false);
  };

  extendRenewalStatus = (query) => {
    return this.extendStatusQuery(query, true);
  };

  extendStatusQuery = (query, isRenewal) => {
    return {
      ...query,
      isRenewal,
      isPending: this.formData.isPending,
      isRegistered: this.formData.isRegistered,
      isDead: this.formData.isDead
    };
  };
}

export class CasesCriteriaSearchBuilderTopic extends Topic {
  readonly key = 'casesCriteria';
  readonly title = 'taskPlanner.searchBuilder.cases.header';
  readonly component = CasesCriteriaSearchBuilderComponent;
  constructor(public params: CasesCriteriaSearchBuilderTopicParams) {
    super();
  }
}

export class CasesCriteriaSearchBuilderTopicParams extends TopicParam { }
