import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { StepsPersistenceService } from 'search/multistepsearch/steps.persistence.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import * as _ from 'underscore';
import { SearchHelperService } from '../../common/search-helper.service';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-details',
  templateUrl: './details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DetailsComponent extends CaseSearchTopicBaseComponent implements OnInit, TopicContract {
  validCombinationDescriptionsMap: any;
  extendValidCombinationPickList: any;

  constructor(
    public vcService: CaseValidCombinationService,
    public persistenceService: StepsPersistenceService,
    public casehelper: SearchHelperService,
    public cdRef: ChangeDetectorRef,
    public translate: TranslateService,
    public notificationService: NotificationService) {
    super(persistenceService, casehelper, cdRef);
    this.validCombinationDescriptionsMap =
      vcService.validCombinationDescriptionsMap;
    this.extendValidCombinationPickList =
      vcService.extendValidCombinationPickList;
  }

  ngOnInit(): void {
    this.onInit();
    this.vcService.initFormData(this.formData);
  }

  loadFormData = (formData): void => {
    this.vcService.initFormData(formData);
    this.formData = formData;
    _.assign(this.topic, { formData });
    this.cdRef.detectChanges();
  };

  isCaseCategoryEnabled = () => {
    const isEnabled = !this.vcService.isCaseCategoryDisabled();
    if (!isEnabled) {
      this.formData.caseCategoryOperator = this.viewData.model.caseCategoryOperator;
      this.formData.caseCategory = null;
    }

    return isEnabled;
  };

  isIncludeGroupMembersEnabled = () => {
    if (
      this.formData.jurisdiction &&
      _.any(this.formData.jurisdiction, (j: any) => {
        return j.isGroup;
      })
    ) {
      return true;
    }

    this.formData.includeGroupMembers = false;

    return false;
  };

  isIncludeWhereDesignatedEnabled = () => {
    if (this.formData.jurisdiction) {

      return true;
    }

    this.formData.includeWhereDesignated = false;

    return false;
  };

  updateInternational = () => {
    if (this.formData.international === false) {
      this.formData.local = true;
      this.cdRef.detectChanges();
    }
  };

  updateLocal = () => {
    if (this.formData.local === false) {
      this.formData.international = true;
      this.cdRef.detectChanges();
    }
  };

  handleCaseCategoryOperatorChanged = () => {
    if (
      this.formData.caseCategoryOperator === SearchOperator.exists ||
      this.formData.caseCategoryOperator === SearchOperator.notExists
    ) {
      this.formData.caseCategory = null;
    }
  };

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;
    const formDataObj: any = {
      subTypeKey: this.casehelper.buildStringFilterFromTypeahead(
        formData.subType,
        formData.subTypeOperator
      ),
      basisKey: this.casehelper.buildStringFilterFromTypeahead(
        formData.basis,
        formData.basisOperator
      ),
      officeKeys: this.casehelper.buildStringFilterFromTypeahead(
        formData.caseOffice,
        formData.caseOfficeOperator
      ),
      countryCodes: this.casehelper.buildStringFilterFromTypeahead(
        formData.jurisdiction,
        formData.jurisdictionOperator,
        {
          includeDesignations: formData.includeWhereDesignated ? 1 : 0,
          includeMembers: formData.includeGroupMembers ? 1 : 0
        }
      ),
      classes: this.casehelper.buildStringFilter(
        formData.class,
        formData.classOperator,
        {
          isLocal: formData.local ? 1 : 0,
          isInternational: formData.international ? 1 : 0
        }
      ),
      includeDraftCase: formData.includeDraftCases ? 1 : 0,
      categoryKey: this.casehelper.buildStringFilterFromTypeahead(
        formData.caseCategory,
        formData.caseCategoryOperator
      ),
      propertyTypeKeys: this.buildPropertyTypeKeys(
        formData.propertyType,
        formData.propertyTypeOperator
      )
    };

    const caseTypeDataKey = !this.topic.params.viewData.allowMultipleCaseTypeSelection
      ? 'caseTypeKey'
      : 'caseTypeKeys';

    formDataObj[caseTypeDataKey] = this.casehelper.buildStringFilterFromTypeahead(
      formData.caseType,
      formData.caseTypeOperator,
      {
        includeCRMCases: 0
      }
    );

    return formDataObj;
  };

  checkForCeasedCountry = (items: Array<any>): void => {
    if (items === null || items.length === 0) {
      return;
    }

    const ceasedCountrys = _.filter(items, (item): boolean => {
      return item.isCeased === true;
    });

    if (ceasedCountrys.length <= 0) {
      return;
    }
    let message = ceasedCountrys.length === 1 ? this.translate.instant('ceasedCountry.single') : this.translate.instant('ceasedCountry.multiple');
    message = _.pluck(ceasedCountrys, 'value').join(', ') + message;
    this.notificationService.info({ message, continue: 'Ok', title: this.translate.instant('modal.information') });
  };

  buildPropertyTypeKeys = (values, operator) => {
    if (this.casehelper.isFilterApplicable(operator, values)) {

      return {
        operator,
        PropertyTypeKey: values ? values.map(j => ({ value: j.code })) : []
      };
    }

    return null;
  };
}
