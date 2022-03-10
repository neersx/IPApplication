namespace inprotech.portfolio.cases {
    'use strict';
    describe('inprotech.portfolio.cases.caseValidCombinationService', () => {
        'use strict';
        let controller: () => CaseValidCombinationService;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');

            controller = () => {
                let c = new CaseValidCombinationService();
                return c;
            }
        });

        describe('extend valid combination pick list', () => {
            it('appends valid property filters to the query', () => {
                let c = controller();
                let query: any = { search: 'forSomething' };
                let formData = {
                    caseType: {
                        value: 'Properties',
                        code: 'P'
                    },
                    jurisdiction: {
                        value: 'Australia',
                        code: 'AU'
                    },
                    propertyType: {
                        value: 'Patent',
                        code: 'P'
                    },
                    caseCategory: {
                        value: 'Normal',
                        code: 'N'
                    }
                };
                c.initFormData(formData);

                let r = c.extendValidCombinationPickList(query);
                expect(r.search).toEqual('forSomething');
                expect(r.caseType).toEqual('P');
                expect(r.jurisdiction).toEqual('AU');
                expect(r.propertyType).toEqual('P');
                expect(r.caseCategory).toEqual('N');
                expect(r.caseTypeModel).toBe(formData.caseType);
                expect(r.jurisdictionModel).toBe(formData.jurisdiction);
                expect(r.propertyTypeModel).toBe(formData.propertyType);
                expect(r.caseCategoryModel).toBe(formData.caseCategory);
            });

            it('handles multi-pick pick lists', () => {
                let c = controller();
                let query: any = { search: 'forSomething' };
                let formData = {
                    caseType: [{
                        value: 'Properties',
                        code: 'P'
                    }],
                    jurisdiction: [{
                        value: 'Australia',
                        code: 'AU'
                    }, {
                        value: 'USA',
                        code: 'USA'
                    }]
                };
                c.initFormData(formData);

                let r = c.extendValidCombinationPickList(query);
                expect(r.caseType).toEqual('P');
                // only one item can be selected
                expect(r.jurisdiction).toEqual(null);
            });

            it('returns empty values if associated operator is not \'Equal To\'', () => {
                let c = controller();
                let query: any = { search: 'forSomething' };
                let formData = {
                    caseType: [{
                        value: 'Properties',
                        code: 'P'
                    }],
                    caseTypeOperator: '0',
                    jurisdiction: [{
                        value: 'Australia',
                        code: 'AU'
                    }],
                    jurisdictionOperator: '1'
                };
                c.initFormData(formData);
                let r = c.extendValidCombinationPickList(query);
                expect(r.caseType).toEqual('P');

                // invalid operator
                expect(r.jurisdiction).toEqual(null);
            });
        });

        describe('disable date of law', function() {
            it('is enabled if jurisdiction and property type are selected otherwise it is disabled', function() {
                let c = controller();
                c.formData = {
                    jurisdiction: {
                        key: 1
                    },
                    propertyType: {
                        key: 2
                    },
                    dateOfLaw: 1
                };
                let r = c.isDateOfLawDisabled();

                expect(r).toBe(false);
                expect(c.formData.dateOfLaw).toBe(1);

                c.formData.jurisdiction = null;
                r = c.isDateOfLawDisabled();
                expect(r).toBe(true);
                expect(c.formData.dateOfLaw).toBe(null);
            });
        });

        describe('disable case category', function() {
            it('is enabled if caseType selected otherwise it is disabled', function() {
                let c = controller();
                c.formData = {
                    caseType: {
                        key: 1,
                        code: 1
                    },
                    caseCategory: 1
                };

                let r = c.isCaseCategoryDisabled();
                expect(r).toBe(false);
                expect(c.formData.caseCategory).toBe(1);

                c.formData.caseType = null;
                r = c.isCaseCategoryDisabled();

                expect(r).toBe(true);
                expect(c.formData.caseCategory).toBe(null);
            });

            it('is disabled if caseType operator exists and is not 0', function() {
                let c = controller();
                c.formData = {
                    caseType: {
                        key: 1,
                        code: 1
                    },
                    caseCategory: 1
                };

                c.formData.caseTypeOperator = '0';
                let r = c.isCaseCategoryDisabled();
                expect(r).toBe(false);

                c.formData.caseTypeOperator = '1';
                r = c.isCaseCategoryDisabled();
                expect(r).toBe(true);

                c.formData.caseTypeOperator = null;
                r = c.isCaseCategoryDisabled();
                expect(r).toBe(false);
            });
        });

        describe('validCombinationMap', () => {
            let c: ICaseValidCombinationService;
            beforeEach(() => {
                c = controller();
            })

            it('returns valid combination descriptions', function() {
                let formData = {
                    caseType: {
                        value: 'Properties',
                        key: 'P'
                    },
                    jurisdiction: {
                        value: 'Australia',
                        key: 'AU'
                    },
                    propertyType: {
                        value: 'Patent',
                        key: 'P'
                    },
                    caseCategory: {
                        value: 'Normal',
                        key: 'N'
                    }
                };
                c.initFormData(formData);

                expect(c.validCombinationDescriptionsMap.propertyTypes()).toEqual({ jurisdiction: 'Australia' });
                expect(c.validCombinationDescriptionsMap.caseCategories()).toEqual({ caseType: 'Properties', jurisdiction: 'Australia', propertyType: 'Patent' });
                expect(c.validCombinationDescriptionsMap.subTypes()).toEqual({ caseType: 'Properties', jurisdiction: 'Australia', propertyType: 'Patent', caseCategory: 'Normal' });
                expect(c.validCombinationDescriptionsMap.basis()).toEqual({ caseType: 'Properties', jurisdiction: 'Australia', propertyType: 'Patent', caseCategory: 'Normal' });
                expect(c.validCombinationDescriptionsMap.actions()).toEqual({ caseType: 'Properties', jurisdiction: 'Australia', propertyType: 'Patent' });
                expect(c.validCombinationDescriptionsMap.datesOfLaw()).toEqual({ jurisdiction: 'Australia', propertyType: 'Patent' });

                formData.caseCategory = null;
                // basis fallback
                expect(c.validCombinationDescriptionsMap.basis()).toEqual({ jurisdiction: 'Australia', propertyType: 'Patent' });

                formData.propertyType = null;
                // case category fallback
                expect(c.validCombinationDescriptionsMap.caseCategories()).toEqual(null);
            });

            it('returns valid combination for Case Category with Case Type only', function() {
                c.initFormData({
                    caseType: {
                        value: 'Properties',
                        key: 'P'
                    }
                });

                expect(c.validCombinationDescriptionsMap.caseCategories()).toEqual(null);
            });

            it('returns null if no valid combination', function() {
                c.initFormData({});
                expect(c.validCombinationDescriptionsMap.propertyTypes()).toBe(null);
                expect(c.validCombinationDescriptionsMap.caseCategories()).toBe(null);
                expect(c.validCombinationDescriptionsMap.subTypes()).toBe(null);
                expect(c.validCombinationDescriptionsMap.basis()).toBe(null);
                expect(c.validCombinationDescriptionsMap.actions()).toBe(null);
                expect(c.validCombinationDescriptionsMap.datesOfLaw()).toBe(null);
            });
        });

        describe('initialisation', function() {
            let c: ICaseValidCombinationService;
            beforeEach(() => {
                c = controller();
            });

            it('marks flag as initialised, on initDataForm', function() {
                c.initFormData({});
                expect(c.isFormDataInitialised()).toBeTruthy();
            });

            it('resets flag as initialised, on resetFormData', function() {
                c.initFormData({});
                c.resetFormData();
                expect(c.isFormDataInitialised()).toBeFalsy();
            });
        });
    });
}
