import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { ReferencesComponent } from '.';
describe('ReferencesComponent', () => {
    let c: ReferencesComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        caseHelpermock.buildStringFilter.mockReturnValue({ value: '123', operator: '2' });
        c = new ReferencesComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, TranslateServiceMock as any, cdr as any);
        viewData = {
            isExternal: false,
            nameTypes: [{ key: 'a' }],
            numberTypes: []
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'References',
            title: 'References'
        };
        c.numberTypes = [];
        c.nameTypes = [{ key: 'a' }];
    });
    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));
    it('initialises defaults', () => {
        expect(c.numberTypes).toEqual(viewData.numberTypes);
        expect(c.nameTypes).toEqual(viewData.nameTypes);
    });
    it('should clear checkboxes when official number is cleared', () => {
        c.formData = {
            officialNumber: {},
            searchNumbersOnly: 1,
            searchRelatedCases: 1
        };
        c.officialNumberUpdated();
        expect(c.formData.searchNumbersOnly).toEqual(1);
        expect(c.formData.searchRelatedCases).toEqual(1);

        c.formData.officialNumber = null;
        c.officialNumberUpdated();
        expect(c.formData.searchNumbersOnly).toEqual(false);
        expect(c.formData.searchRelatedCases).toEqual(false);

    });

    it('should return official number filter if applicable', () => {
        c.formData = {
            officialNumberOperator: 0,
            officialNumber: ''
        };

        let r = c.getFilterCriteria();
        expect(r.officialNumber).toEqual({});
        caseHelpermock.buildStringFilter.mockReturnValue({ value: '123', operator: '2' });
        caseHelpermock.isFilterApplicable.mockReturnValue({ operator: '5' });
        c = new ReferencesComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, TranslateServiceMock as any, cdr as any);
        c.formData.officialNumber = '123';
        c.formData.searchNumbersOnly = true;
        c.formData.officialNumberOperator = '0';
        c.formData.officialNumberType = 'ABC';
        c.formData.searchRelatedCases = true;

        r = c.getFilterCriteria();
        expect(r.officialNumber).toEqual({
            number: {
                value: '123',
                useNumericSearch: 1
            },
            operator: '0',
            typeKey: 'ABC',
            useRelatedCase: 1,
            useCurrent: 0
        });
    });

    it('should return case name reference if applicable', () => {
        caseHelpermock.isFilterApplicable.mockReturnValue({ typeKey: 'A', referenceNo: 'AAA', operator: '0' });
        c = new ReferencesComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, TranslateServiceMock as any, cdr as any);
        c.formData.caseNameReference = 'AAA';
        c.formData.caseNameReferenceType = 'A';
        c.formData.caseNameReferenceOperator = '0';
        const r = c.getFilterCriteria();
        expect(r.caseNameReference).toEqual({
            typeKey: 'A',
            referenceNo: 'AAA',
            operator: '0'
        });
    });

    it('should return family list', () => {
        caseHelpermock.buildStringFilter.mockReturnValue({ value: 'f,a,m', operator: '0' });
        caseHelpermock.isFilterApplicable.mockReturnValue({ operator: '5' });
        c = new ReferencesComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, TranslateServiceMock as any, cdr as any);  const r = c.getFilterCriteria();
        c.formData = {
            familyOperator: '0',
            family: [{ key: 'f' }, { key: 'a' }, { key: 'm' }]
        };
        expect(r.familyKey).toEqual({ value: 'f,a,m', operator: '0' });
    });

    it('should return case list if applicable', () => {
        caseHelpermock.isFilterApplicable.mockReturnValue({ operator: '5' });
        c = new ReferencesComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, TranslateServiceMock as any, cdr as any);
         c.formData = {
            caseList: null,
            caseListOperator: '0',
            isPrimeCasesOnly: 1,
            caseListKey: null
        };
        const result = c.getFilterCriteria();
        expect(result.caseList).toEqual({
            caseListKey: {operator: '2', value: '123'},
            isPrimeCasesOnly: 1
        });
    });
});
describe('ReferencesComponent for multiple value', () => {
    let c: ReferencesComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    caseHelpermock.buildStringFilter.mockReturnValue({ value: '1,2', operator: '0' });
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        c = new ReferencesComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, TranslateServiceMock as any, cdr as any);  const r = c.getFilterCriteria();
       viewData = {
            isExternal: false,
            nameTypes: [{ key: 'a' }],
            numberTypes: []
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'References',
            title: 'References'
        };
        c.numberTypes = [];
        c.nameTypes = [{ key: 'a' }];
    });

    it('should return case reference filters multiple value', () => {
        c.formData = {
            yourReferenceOperator: '2',
            yourReference: 'xyz',
            caseReferenceOperator: '0',
            caseReference: '123',
            caseKeys: [{ key: 1 }, { key: 2 }]
        };

        let r = c.getFilterCriteria();
        expect(r.caseKeys).toEqual(jasmine.objectContaining({ value: '1,2', operator: '0' }));
        expect(r.caseReference).not.toBeDefined();
        caseHelpermock.buildStringFilter.mockReturnValue({ value: 'xyz', operator: '2' });
        caseHelpermock.isFilterApplicable.mockReturnValue({ operator: '5' });
        c = new ReferencesComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, TranslateServiceMock as any, cdr as any);
        c.isExternal = true;
        r = c.getFilterCriteria();
        expect(r.caseReference).toBeDefined();
        expect(r.clientReference).toEqual(jasmine.objectContaining({ value: 'xyz', operator: '2' }));
    });
});
