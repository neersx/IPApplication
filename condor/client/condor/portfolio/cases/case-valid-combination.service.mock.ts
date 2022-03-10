namespace inprotech.portfolio.cases {
    class CaseValidCombinationServiceMock implements ICaseValidCombinationService {
        'use strict';

        validCombinationDescriptionsMap: any;
        public returnValues: any;

        constructor() {
            this.returnValues = {};
            spyOn(this, 'initFormData');
            spyOn(this, 'addExtendFunctions');
            spyOn(this, 'extendValidCombinationPickList');
            spyOn(this, 'isCaseCategoryDisabled').and.callThrough();
            spyOn(this, 'isDateOfLawDisabled').and.callThrough();
        }

        initFormData = () => { };
        addExtendFunctions = () => { };
        extendValidCombinationPickList = (query) => { };
        isCaseCategoryDisabled = () => {
            return this.returnValues['isCaseCategoryDisabled'];
        };
        isDateOfLawDisabled = () => {
            return this.returnValues['isDateOfLawDisabled'];
        };

        setReturnValue = (property: string, value: any) => {
            this.returnValues[property] = value;
        };

        isFormDataInitialised = () => {
            return true;
        };

        resetFormData = () => { };
    }
    angular.module('inprotech.mocks')
        .service('caseValidCombinationServiceMock', CaseValidCombinationServiceMock);
}
