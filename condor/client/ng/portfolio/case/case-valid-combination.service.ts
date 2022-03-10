import { Injectable } from '@angular/core';
import { SearchOperator } from 'search/common/search-operators';
import * as _ from 'underscore';

export interface ICaseValidCombinationService {
  validCombinationDescriptionsMap: any;
  initFormData(formData): void;
  addExtendFunctions(vm): void;
  extendValidCombinationPickList(query): any;
  isCaseCategoryDisabled(): Boolean;
  isDateOfLawDisabled(): Boolean;
}

@Injectable()
export class CaseValidCombinationService implements ICaseValidCombinationService {
  formData: any;
  validCombinationDescriptionsMap: any;

  constructor() {
    this.validCombinationDescriptionsMap = {
      propertyTypes: this.getPropertyTypeFilter,
      caseCategories: this.getCaseCategoryFilter,
      subTypes: this.getSubTypeFilter,
      basis: this.getBasisFilter,
      actions: this.getActionFilter,
      datesOfLaw: this.getDateOfLawFilter,
      checklists: this.getChecklistTypeFilter
    };
  }

  initFormData = (formData: any): void => {
    this.formData = formData;
  };

  addExtendFunctions = (vm: any): void => {
    vm.extendValidCombinationPickList = this.extendValidCombinationPickList;
    vm.isCaseCategoryDisabled = this.isCaseCategoryDisabled;
    vm.isDateOfLawDisabled = this.isDateOfLawDisabled;
    vm.picklistValidCombination = this.validCombinationDescriptionsMap;
  };

  extendValidCombinationPickList = (query: any): any => {
    const vc = this.getValidCombinationValues('code');

    return {
      ...query, ...{
        caseType: vc.caseType,
        jurisdiction: vc.jurisdiction,
        propertyType: vc.propertyType,
        caseCategory: vc.caseCategory,
        caseTypeModel: this.formData.caseType,
        jurisdictionModel: this.formData.jurisdiction,
        propertyTypeModel: this.formData.propertyType,
        caseCategoryModel: this.formData.caseCategory
      }
    };
  };

  isDateOfLawDisabled = (): Boolean => {
    const isDisabled = !(this.formData.jurisdiction && this.formData.propertyType);

    if (isDisabled && this.formData.dateOfLaw != null) {
      this.formData.dateOfLaw = null;
    }

    return isDisabled;
  };

  isCaseCategoryDisabled = (): boolean => {
    let isDisabled = false;
    if ((this.formData.caseTypeOperator && this.formData.caseTypeOperator !== SearchOperator.equalTo) || (this.formData.caseType === undefined || this.formData.caseType === null || this.formData.caseType.length === 0 || this.formData.caseType.length > 1)) {
      isDisabled = true;
    }

    return isDisabled;
  };

  getValidCombinationValues(propertyName): any {
    const caseType = this.getValue('caseType', propertyName);
    const jurisdiction = this.getValue('jurisdiction', propertyName);
    const propertyType = this.getValue('propertyType', propertyName);
    const caseCategory = this.getValue('caseCategory', propertyName);

    return {
      caseType,
      jurisdiction,
      propertyType,
      caseCategory
    };
  }

  private getValue(itemName, propertyName): any {
    if (!this.formData[itemName]) {
      return '';
    }
    // case search fields must have equals to operator
    if (
      this.formData[itemName + 'Operator'] &&
      this.formData[itemName + 'Operator'] !== SearchOperator.equalTo
    ) {
      return '';
    }

    if (Array.isArray(this.formData[itemName])) {
      return this.formData[itemName].length === 1
        ? this.formData[itemName][0][propertyName]
        : '';
    }

    return this.formData[itemName][propertyName];
  }

  private readonly getPropertyTypeFilter = (): { jurisdiction: any } => {
    const vc = this.getValidCombinationValues('value');
    if (vc.jurisdiction) {
      return { jurisdiction: vc.jurisdiction };
    }

    return null;
  };

  private readonly getActionFilter = (): { caseType: any, jurisdiction: any, propertyType: any } => {
    const vc = this.getValidCombinationValues('value');
    if (_.all([vc.caseType, vc.jurisdiction, vc.propertyType])) {
      return {
        caseType: vc.caseType,
        jurisdiction: vc.jurisdiction,
        propertyType: vc.propertyType
      };
    }

    return null;
  };

  private readonly getCaseCategoryFilter = (): { caseType: any } => {
    const actionFilter = this.getActionFilter();
    if (actionFilter) {
      return actionFilter;
    }

    return null;
  };

  private readonly getSubTypeFilter = (): { caseType: any, jurisdiction: any, propertyType: any, caseCategory: any } => {
    const vc = this.getValidCombinationValues('value');
    if (
      _.all([vc.caseType, vc.jurisdiction, vc.propertyType, vc.caseCategory])
    ) {
      return {
        caseType: vc.caseType,
        jurisdiction: vc.jurisdiction,
        propertyType: vc.propertyType,
        caseCategory: vc.caseCategory
      };
    }

    return null;
  };

  private readonly getBasisFilter = (): any => {
    const subTypeCombination = this.getSubTypeFilter();
    if (subTypeCombination) {
      return subTypeCombination;
    }

    const vc = this.getValidCombinationValues('value');
    if (_.all([vc.jurisdiction, vc.propertyType])) {
      return {
        jurisdiction: vc.jurisdiction,
        propertyType: vc.propertyType
      };
    }

    return null;
  };

  private readonly getDateOfLawFilter = (): { jurisdiction: any, propertyType: any } => {
    const vc = this.getValidCombinationValues('value');
    if (_.all([vc.jurisdiction, vc.propertyType])) {
      return {
        jurisdiction: vc.jurisdiction,
        propertyType: vc.propertyType
      };
    }

    return null;
  };

  private readonly getChecklistTypeFilter = (): { caseType: any, jurisdiction: any, propertyType: any } => {
    const vc = this.getValidCombinationValues('value');
    if (_.all([vc.caseType, vc.jurisdiction, vc.propertyType])) {
      return {
        caseType: vc.caseType,
        jurisdiction: vc.jurisdiction,
        propertyType: vc.propertyType
      };
    }

    return null;
  };
}