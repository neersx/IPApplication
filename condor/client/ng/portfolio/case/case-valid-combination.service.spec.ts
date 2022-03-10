import { TestBed } from '@angular/core/testing';
import { CaseValidCombinationService } from './case-valid-combination.service';

describe('CaseValidCombinationService', () => {
    let service: CaseValidCombinationService;
    beforeEach(() => {
        TestBed.configureTestingModule({
            providers: [
                CaseValidCombinationService
            ]
        });
        service = TestBed.get(CaseValidCombinationService);
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });
    describe('extend valid combination pick list', () => {
        it('appends valid property filters to the query', () => {
            const query: any = { search: 'forSomething' };
            const formData = {
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
            service.initFormData(formData);

            const r = service.extendValidCombinationPickList(query);
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
            const query: any = { search: 'forSomething' };
            const formData = {
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
            service.initFormData(formData);

            const r = service.extendValidCombinationPickList(query);
            expect(r.caseType).toEqual('P');
            // only one item can be selected
            expect(r.jurisdiction).toEqual('');
        });

        it('returns empty values if associated operator is not \'Equal To\'', () => {
            const query: any = { search: 'forSomething' };
            const formData = {
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
            service.initFormData(formData);
            const r = service.extendValidCombinationPickList(query);
            expect(r.caseType).toEqual('P');

            // invalid operator
            expect(r.jurisdiction).toEqual('');
        });
    });

    describe('disable date of law', () => {
        it('is enabled if jurisdiction and property type are selected otherwise it is disabled', () => {
            service.formData = {
                jurisdiction: {
                    key: 1
                },
                propertyType: {
                    key: 2
                },
                dateOfLaw: 1
            };
            let r = service.isDateOfLawDisabled();

            expect(r).toBe(false);
            expect(service.formData.dateOfLaw).toBe(1);

            service.formData.jurisdiction = null;
            r = service.isDateOfLawDisabled();
            expect(r).toBe(true);
            expect(service.formData.dateOfLaw).toBe(null);
        });
    });

    describe('disable case category', () => {
        it('is enabled if caseType selected otherwise it is disabled', () => {
            service.formData = {
                caseType: {
                    key: 1,
                    code: 1
                },
                caseCategory: 1
            };

            let r = service.isCaseCategoryDisabled();
            expect(r).toBe(false);
            expect(service.formData.caseCategory).toBe(1);

            service.formData.caseType = undefined;
            r = service.isCaseCategoryDisabled();

            expect(r).toBe(true);
        });

        it('is disabled if caseType operator exists and is not 0', () => {
            service.formData = {
                caseType: {
                    key: 1,
                    code: 1
                },
                caseCategory: 1
            };

            service.formData.caseTypeOperator = '0';
            let r = service.isCaseCategoryDisabled();
            expect(r).toBe(false);

            service.formData.caseTypeOperator = '1';
            r = service.isCaseCategoryDisabled();
            expect(r).toBe(true);

            service.formData.caseTypeOperator = null;
            r = service.isCaseCategoryDisabled();
            expect(r).toBe(false);
        });
    });

    describe('validCombinationMap', () => {
        it('returns valid combination descriptions', () => {
            const formData = {
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
            service.initFormData(formData);

            expect(service.validCombinationDescriptionsMap.propertyTypes()).toEqual({ jurisdiction: 'Australia' });
            expect(service.validCombinationDescriptionsMap.caseCategories()).toEqual({ caseType: 'Properties', jurisdiction: 'Australia', propertyType: 'Patent' });
            expect(service.validCombinationDescriptionsMap.subTypes()).toEqual({ caseType: 'Properties', jurisdiction: 'Australia', propertyType: 'Patent', caseCategory: 'Normal' });
            expect(service.validCombinationDescriptionsMap.basis()).toEqual({ caseType: 'Properties', jurisdiction: 'Australia', propertyType: 'Patent', caseCategory: 'Normal' });
            expect(service.validCombinationDescriptionsMap.actions()).toEqual({ caseType: 'Properties', jurisdiction: 'Australia', propertyType: 'Patent' });
            expect(service.validCombinationDescriptionsMap.datesOfLaw()).toEqual({ jurisdiction: 'Australia', propertyType: 'Patent' });

            formData.caseCategory = null;
            // basis fallback
            expect(service.validCombinationDescriptionsMap.basis()).toEqual({ jurisdiction: 'Australia', propertyType: 'Patent' });

            formData.propertyType = null;
            // case category fallback
            expect(service.validCombinationDescriptionsMap.caseCategories()).toEqual(null);
        });

        it('returns null for Case Category with Case Type only', () => {
            service.initFormData({
                caseType: {
                    value: 'Properties',
                    key: 'P'
                }
            });

            expect(service.validCombinationDescriptionsMap.caseCategories()).toEqual(null);
        });

        it('returns null if no valid combination', () => {
            service.initFormData({});
            expect(service.validCombinationDescriptionsMap.propertyTypes()).toBe(null);
            expect(service.validCombinationDescriptionsMap.caseCategories()).toBe(null);
            expect(service.validCombinationDescriptionsMap.subTypes()).toBe(null);
            expect(service.validCombinationDescriptionsMap.basis()).toBe(null);
            expect(service.validCombinationDescriptionsMap.actions()).toBe(null);
            expect(service.validCombinationDescriptionsMap.datesOfLaw()).toBe(null);
        });
    });
});
