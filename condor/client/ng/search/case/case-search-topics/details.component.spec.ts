import { NotificationServiceMock } from './../../../ajs-upgraded-providers/notification-service.mock';

import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, CaseValidCombinationServiceMock, ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { DetailsComponent } from '.';

describe('DetailsComponent', () => {
    let c: DetailsComponent;
    let translateServiceMock: TranslateServiceMock;
    let notificationServiceMock: NotificationServiceMock;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    let caseValid: CaseValidCombinationServiceMock;
    beforeEach(() => {
        translateServiceMock = new TranslateServiceMock();
        notificationServiceMock = new NotificationServiceMock();
        cdr = new ChangeDetectorRefMock();
        caseValid = new CaseValidCombinationServiceMock();
        const caseHelpermock = new CaseSearchHelperServiceMock();
        caseHelpermock.isFilterApplicable.mockReturnValue({ operator: {}, PropertyTypeKey: [({ value: 'Property1' }), ({ value: 'Property2' })] });
        c = new DetailsComponent(caseValid as any, StepsPersistanceSeviceMock as any,
            caseHelpermock as any, cdr as any, translateServiceMock as any, notificationServiceMock as any);
        viewData = {
            isExternal: false,
            nameTypes: [{ key: 'a' }],
            numberTypes: []
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'Details',
            title: 'Details'
        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('should reassign the formdata into topic', () => {
        c.formData = {
            id: '1',
            caseOfficeOperator: '0',
            caseTypeOperator: '0',
            jurisdictionOperator: '0',
            includeDraftCases: false,
            includeWhereDesignated: false,
            includeGroupMembers: false,
            propertyTypeOperator: '0',
            caseCategoryOperator: '0',
            subTypeOperator: '0',
            basisOperator: '0',
            classOperator: '0',
            local: true,
            international: true
        };

        c.loadFormData(c.formData);
        expect(c.topic).toHaveProperty('formData');
    });

    it('should enable group members checkbox when a group jurisdiction is selected', () => {
        c.formData = {
            includeGroupMembers: true,
            jurisdiction: [{ isGroup: true }]
        };
        let r = c.isIncludeGroupMembersEnabled();
        expect(r).toEqual(true);
        expect(c.formData.includeGroupMembers).toEqual(true);

        c.formData.jurisdiction[0].isGroup = false;
        r = c.isIncludeGroupMembersEnabled();
        expect(r).toEqual(false);
        expect(c.formData.includeGroupMembers).toEqual(false);
    });

    it('should enable designated jurisdictions checkbox when any jurisdiction selected', () => {
        c.formData = {
            jurisdiction: {}
        };
        let r = c.isIncludeWhereDesignatedEnabled();
        expect(r).toEqual(true);
        c.formData.includeWhereDesignated = true;
        c.formData.jurisdiction = null;
        r = c.isIncludeWhereDesignatedEnabled();
        expect(r).toEqual(false);
        expect(c.formData.includeWhereDesignated).toEqual(false);
    });
    it('should ensure either International or Local class checkbox is ticked', () => {
        c.formData = {
            international: false,
            local: false
        };
        c.updateInternational();
        expect(c.formData.local).toEqual(true);
        expect(c.formData.international).toEqual(false);

        c.formData.local = false;
        c.updateLocal();
        expect(c.formData.international).toEqual(true);
        expect(c.formData.local).toEqual(false);
    });
    it('should generate propertyKey correctly', () => {
        c.formData = {
            propertyTypeOperator: '5',
            propertyType: [{ code: 'Property1' }, { code: 'Property2' }]
        };
        const data = c.getFilterCriteria();
        expect(data.propertyTypeKeys).toEqual({ operator: '5', PropertyTypeKey: [({ value: 'Property1' }), ({ value: 'Property2' })] });
    });

    it('should generate includeDraftCase correctly', () => {
        c.formData = {
            includeDraftCases: true
        };

        const data = c.getFilterCriteria();
        expect(data.includeDraftCase).toEqual(1);
    });
});

describe('DetailsComponent case detail filters with single case type selection', () => {
    let c: DetailsComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    let translateServiceMock: TranslateServiceMock;
    let notificationServiceMock: NotificationServiceMock;
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        translateServiceMock = new TranslateServiceMock();
        notificationServiceMock = new NotificationServiceMock();
        const mock = new CaseSearchHelperServiceMock();
        mock.buildStringFilterFromTypeahead.mockReturnValue({ value: 'Properties', operator: '0' });
        mock.buildStringFilter.mockReturnValue({ value: 'Class', operator: '0', isLocal: 1, isInternational: 0 });
        c = new DetailsComponent(CaseValidCombinationServiceMock as any, StepsPersistanceSeviceMock as any,
            mock as any, cdr as any, translateServiceMock as any, notificationServiceMock as any);
        viewData = {
            isExternal: false,
            nameTypes: [{ key: 'a' }],
            numberTypes: []
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'Details',
            title: 'Details'
        };
    });
    it('should return case detail filters with single case type selection', () => {
        c.formData = {
            classOperator: '0',
            caseTypeOperator: '0',
            caseType: { code: 'Properties' },
            class: 'Class',
            international: false,
            local: true,
            propertyTypeOperator: '0',
            propertyType: [{ code: 'Property1' }, { code: 'Propert2' }]
        };
        const data = c.getFilterCriteria();
        expect(data.caseTypeKey).toEqual(jasmine.objectContaining({ value: 'Properties', operator: '0' }));
        expect(data.classes).toEqual(jasmine.objectContaining({ value: 'Class', operator: '0', isLocal: 1, isInternational: 0 }));
    });
});
describe('DetailsComponent case detail filters with multiple case type selection', () => {
    let c: DetailsComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    let translateServiceMock: TranslateServiceMock;
    let notificationServiceMock: NotificationServiceMock;
    const caseSearchHelperSeceMock = {
        getKeysFromTypeahead: jest.fn(), buildStringFilterFromTypeahead: jest.fn().mockReturnValue({ value: 'Properties,Assignments', operator: '0', includeCRMCases: 0 }),
        buildStringFilter: jest.fn().mockReturnValue({ value: 'Class', operator: '0', isLocal: 1, isInternational: 0 }), buildFromToValues: jest.fn(), isFilterApplicable: jest.fn()
    };
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        translateServiceMock = new TranslateServiceMock();
        notificationServiceMock = new NotificationServiceMock();
        const mock = new CaseSearchHelperServiceMock();
        mock.buildStringFilterFromTypeahead.mockReturnValue({ value: 'Properties,Assignments', operator: '0', includeCRMCases: 0 });
        mock.buildStringFilter.mockReturnValue({ value: 'Class', operator: '0', isLocal: 1, isInternational: 0 });
        c = new DetailsComponent(CaseValidCombinationServiceMock as any, StepsPersistanceSeviceMock as any,
            mock as any, cdr as any, translateServiceMock as any, notificationServiceMock as any);
        viewData = {
            isExternal: false,
            nameTypes: [{ key: 'a' }],
            numberTypes: []
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'Details',
            title: 'Details'
        };
    });
    it('should return case detail filters with single case type selection', () => {
        c.formData = {
            classOperator: '0',
            caseTypeOperator: '0',
            caseType: { code: 'Properties' },
            class: 'Class',
            international: false,
            local: true,
            propertyTypeOperator: '0',
            propertyType: [{ code: 'Property1' }, { code: 'Propert2' }]
        };
        const data = c.getFilterCriteria();
        expect(data.caseTypeKey).toEqual(jasmine.objectContaining({ value: 'Properties,Assignments', operator: '0', includeCRMCases: 0 }));
        expect(data.classes).toEqual(jasmine.objectContaining({ value: 'Class', operator: '0', isLocal: 1, isInternational: 0 }));
    });
});
describe('DetailsComponent countryCodes correctly', () => {
    let c: DetailsComponent;
    let viewData: any;
    let translateServiceMock: TranslateServiceMock;
    let notificationServiceMock: NotificationServiceMock;
    let cdr: ChangeDetectorRefMock;
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        translateServiceMock = new TranslateServiceMock();
        notificationServiceMock = new NotificationServiceMock();
        const caseHelpermock = new CaseSearchHelperServiceMock();
        caseHelpermock.buildStringFilterFromTypeahead.mockReturnValue({ value: 'A,B,C', operator: '0', includeDesignations: 1, includeMembers: 1 });
        caseHelpermock.buildStringFilter.mockReturnValue({ value: 'Class', operator: '0', isLocal: 1, isInternational: 0 });
        c = new DetailsComponent(CaseValidCombinationServiceMock as any, StepsPersistanceSeviceMock as any,
            caseHelpermock as any, cdr as any, translateServiceMock as any, notificationServiceMock as any);
        viewData = {
            isExternal: false,
            nameTypes: [{ key: 'a' }],
            numberTypes: []
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'Details',
            title: 'Details'
        };
    });
    it('should generate countryCodes correctly', () => {
        c.formData = {
            jurisdictionOperator: '0',
            jurisdiction: [{ code: 'A' }, { code: 'B' }, { code: 'C' }],
            includeWhereDesignated: true,
            includeGroupMembers: true
        };

        const data = c.getFilterCriteria();
        expect(data.countryCodes).toEqual({ value: 'A,B,C', operator: '0', includeDesignations: 1, includeMembers: 1 });
    });

    it('should show warning alert when any of the selected country is ceased', () => {
        const countries = [
            { id: 'c1', isCeased: true, value: 'country1' },
            { id: 'c2', isCeased: false, value: 'country2' }
        ];
        c.checkForCeasedCountry(countries);
        expect(c.notificationService.info).toHaveBeenCalled();
    });

    it('should not show warning alert when any of the selected country is not ceased', () => {
        const countries = [
            { id: 'c1', isCeased: false, value: 'country1' },
            { id: 'c2', isCeased: false, value: 'country2' }
        ];
        c.checkForCeasedCountry(countries);
        expect(c.notificationService.info).not.toHaveBeenCalled();
    });

});