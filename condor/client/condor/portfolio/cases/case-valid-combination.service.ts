namespace inprotech.portfolio.cases {
  'use strict';

  export interface ICaseValidCombinationService {
    validCombinationDescriptionsMap: any;
    initFormData(formData);
    addExtendFunctions(vm);
    extendValidCombinationPickList(query);
    isCaseCategoryDisabled();
    isDateOfLawDisabled();
    isFormDataInitialised(): Boolean;
    resetFormData(): void;
  }

  export class CaseValidCombinationService
    implements ICaseValidCombinationService {
    isInitialised: boolean;
    formData: any;
    validCombinationDescriptionsMap: any;

    constructor() {
      this.validCombinationDescriptionsMap = {
        propertyTypes: this.getPropertyTypeFilter,
        caseCategories: this.getCaseCategoryFilter,
        subTypes: this.getSubTypeFilter,
        basis: this.getBasisFilter,
        actions: this.getActionFilter,
        datesOfLaw: this.getDateOfLawFilter
      };
    }

    initFormData = formData => {
      this.formData = formData;
      this.isInitialised = true;
    };

    resetFormData(): void {
      this.isInitialised = false;
    };

    isFormDataInitialised(): Boolean {
      return this.isInitialised;
    };

    addExtendFunctions = vm => {
      vm.extendValidCombinationPickList = this.extendValidCombinationPickList;
      vm.isCaseCategoryDisabled = this.isCaseCategoryDisabled;
      vm.isDateOfLawDisabled = this.isDateOfLawDisabled;
      vm.picklistValidCombination = this.validCombinationDescriptionsMap;
    };

    extendValidCombinationPickList = query => {
      let vc = this.getValidCombinationValues('code');
      return angular.extend({}, query, {
        caseType: vc.caseType,
        jurisdiction: vc.jurisdiction,
        propertyType: vc.propertyType,
        caseCategory: vc.caseCategory,
        caseTypeModel: this.formData.caseType,
        jurisdictionModel: this.formData.jurisdiction,
        propertyTypeModel: this.formData.propertyType,
        caseCategoryModel: this.formData.caseCategory
      });
    };

    getValidCombinationValues(propertyName) {
      let caseType = this.getValue('caseType', propertyName);
      let jurisdiction = this.getValue('jurisdiction', propertyName);
      let propertyType = this.getValue('propertyType', propertyName);
      let caseCategory = this.getValue('caseCategory', propertyName);
      return {
        caseType: caseType,
        jurisdiction: jurisdiction,
        propertyType: propertyType,
        caseCategory: caseCategory
      };
    }

    getValue(itemName, propertyName) {
      if (!this.formData[itemName]) {
        return null;
      }

      // case search fields must have equals to operator
      if (
        this.formData[itemName + 'Operator'] &&
        this.formData[itemName + 'Operator'] !== '0'
      ) {
        return null;
      }

      if (Array.isArray(this.formData[itemName])) {
        return this.formData[itemName].length === 1
          ? this.formData[itemName][0][propertyName]
          : null;
      }

      return this.formData[itemName][propertyName];
    }

    getPropertyTypeFilter = () => {
      let vc = this.getValidCombinationValues('value');
      if (vc.jurisdiction) {
        return { jurisdiction: vc.jurisdiction };
      }

      return null;
    };

    getActionFilter = () => {
      let vc = this.getValidCombinationValues('value');
      if (_.all([vc.caseType, vc.jurisdiction, vc.propertyType])) {
        return {
          caseType: vc.caseType,
          jurisdiction: vc.jurisdiction,
          propertyType: vc.propertyType
        };
      }
      return null;
    };

    getCaseCategoryFilter = () => {
      let actionFilter = this.getActionFilter();
      if (actionFilter) {
        return actionFilter;
      }

      return null;
    };

    getSubTypeFilter = () => {
      let vc = this.getValidCombinationValues('value');
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

    getBasisFilter = () => {
      let subTypeCombination = this.getSubTypeFilter();
      if (subTypeCombination) {
        return subTypeCombination;
      }

      let vc = this.getValidCombinationValues('value');
      if (_.all([vc.jurisdiction, vc.propertyType])) {
        return {
          jurisdiction: vc.jurisdiction,
          propertyType: vc.propertyType
        };
      }

      return null;
    };

    getDateOfLawFilter = () => {
      let vc = this.getValidCombinationValues('value');
      if (_.all([vc.jurisdiction, vc.propertyType])) {
        return {
          jurisdiction: vc.jurisdiction,
          propertyType: vc.propertyType
        };
      }
      return null;
    };

    isDateOfLawDisabled = () => {
      let isDisabled = !(
        this.formData.jurisdiction && this.formData.propertyType
      );

      if (isDisabled && this.formData.dateOfLaw != null) {
        this.formData.dateOfLaw = null;
      }

      return isDisabled;
    };

    isCaseCategoryDisabled = () => {
      let isDisabled = false;
      if (
        !this.formData.caseType ||
        (_.any(this.formData.caseType) && this.formData.caseType.length > 1) ||
        (this.formData.caseTypeOperator &&
          this.formData.caseTypeOperator !== '0')
      ) {
        isDisabled = true;
      }
      if (isDisabled && this.formData.caseCategory != null) {
        this.formData.caseCategory = null;
      }

      return isDisabled;
    };
  }

  angular
    .module('inprotech.portfolio.cases')
    .service('caseValidCombinationService', CaseValidCombinationService);
}
