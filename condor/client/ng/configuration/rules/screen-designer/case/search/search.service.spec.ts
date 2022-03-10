import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { SearchResult } from 'shared/shared-services/grid-navigation.service';
import { SearchService } from './search.service';

describe('Service: Search', () => {
  let httpMock: HttpClientMock;
  let service: SearchService;
  beforeEach(() => {
    httpMock = new HttpClientMock();
    // tslint:disable-next-line: no-empty
    httpMock.get.mockReturnValue({pipe: (args: any) => {
    }});
    service = new SearchService(httpMock as any, { init: jest.fn(), setNavigationData: jest.fn() } as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('getCaseCriteriasByCharacteristics$', () => {
    it('should call the right api with getCaseCriterias$', () => {
      const queryParams = {
        exampleQueryParams: 'test'
      };
      service.getCaseCriteriasByCharacteristics$({}, queryParams);
      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/search', {
        params: expect.objectContaining({ params: JSON.stringify(queryParams) })
      });
    });

    it('should build the expected criteria filter object', () => {
      const criteriaParams = {
        caseType: { code: 'caseTypeCode' },
        caseCategory: { code: 'caseCategoryCode' },
        program: { key: 'programCode' },
        jurisdiction: { code: 'jurisdictionCode' },
        propertyType: { code: 'propertyTypeCode' },
        subType: { code: 'subTypeCode' },
        basis: { code: 'basisCode' },
        office: { key: 'officeKey' },
        profile: { code: 'profileCode' },
        protectedCriteria: true,
        criteriaNotInUse: true,
        matchType: 'matchType'
      };

      const expectedCriteria = {
        caseType: criteriaParams.caseType.code,
        caseCategory: criteriaParams.caseCategory.code,
        caseProgram: criteriaParams.program.key,
        jurisdiction: criteriaParams.jurisdiction.code,
        propertyType: criteriaParams.propertyType.code,
        subType: criteriaParams.subType.code,
        basis: criteriaParams.basis.code,
        office: criteriaParams.office.key,
        profile: criteriaParams.profile.code,
        includeProtectedCriteria: criteriaParams.protectedCriteria,
        includeCriteriaNotInUse: criteriaParams.criteriaNotInUse,
        matchType: criteriaParams.matchType
      };

      service.getCaseCriteriasByCharacteristics$(criteriaParams, {});

      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/search', {
        params: expect.objectContaining({ criteria: JSON.stringify(expectedCriteria) })
      });
    });

  });

  it('should call the right api with the expected params with getCaseCriteriasData$', () => {
    const queryParams = {
      exampleQueryParams: 'test'
    };
    const criteriaParams = {
      exampleCriteriaParams: 'test'
    };

    service.getCaseCriteriasData$(criteriaParams, queryParams);

    expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/viewData', {
      params: expect.objectContaining({
        q: JSON.stringify(criteriaParams),
        params: JSON.stringify(queryParams)
      })
    });
  });

  describe('getCaseCharacteristics$', () => {
    it('should call the right api with getCaseCharacteristics$', () => {
      const caseKey = 2;
      const purposeCode = 'Test';

      service.getCaseCharacteristics$(caseKey, purposeCode);

      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/characteristics/caseCharacteristics/' + caseKey + '?purposeCode=' + purposeCode);
    });
  });

  describe('getColumnFilterData$', () => {
    it('should call the right api with getColumnFilterData$', () => {
      const queryParams = {
        exampleQueryParams: 'test'
      };
      service.getColumnFilterData$({}, 'column', queryParams);
      expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/filterData', expect.objectContaining({
        params: queryParams,
        column: 'column'
      }));
    });

    it('should build the expected criteria filter object', () => {
      const criteriaParams = {
        caseType: { code: 'caseTypeCode' },
        caseCategory: { code: 'caseCategoryCode' },
        program: { key: 'programCode' },
        jurisdiction: { code: 'jurisdictionCode' },
        propertyType: { code: 'propertyTypeCode' },
        subType: { code: 'subTypeCode' },
        basis: { code: 'basisCode' },
        office: { key: 'officeKey' },
        profile: { code: 'profileCode' },
        protectedCriteria: true,
        criteriaNotInUse: true,
        matchType: 'matchType'
      };

      const expectedCriteria = {
        caseType: criteriaParams.caseType.code,
        caseCategory: criteriaParams.caseCategory.code,
        caseProgram: criteriaParams.program.key,
        jurisdiction: criteriaParams.jurisdiction.code,
        propertyType: criteriaParams.propertyType.code,
        subType: criteriaParams.subType.code,
        basis: criteriaParams.basis.code,
        office: criteriaParams.office.key,
        profile: criteriaParams.profile.code,
        includeProtectedCriteria: criteriaParams.protectedCriteria,
        includeCriteriaNotInUse: criteriaParams.criteriaNotInUse,
        matchType: criteriaParams.matchType
      };

      service.getColumnFilterData$(criteriaParams, 'column', {});

      expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/filterData', expect.objectContaining({
        criteria: expectedCriteria,
        column: 'column'
      }));
    });
  });

  describe('getColumnFilterDataByIds$', () => {
    it('should call the right api with getColumnFilterDataByIds$', () => {
      const queryParams = {
        exampleQueryParams: 'test'
      };
      service.getColumnFilterDataByIds$({}, 'column', queryParams);
      expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/filterDataByIds', expect.objectContaining({
        params: queryParams,
        column: 'column'
      }));
    });

    it('should build the expected criteria filter object', () => {
      const criteriaParams = {
        criteria: [{ id: 'id1' }, { id: 'id2' }]
      };

      const expectedCriteria = ['id1', 'id2'];

      service.getColumnFilterDataByIds$(criteriaParams, 'column', {});

      expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/filterDataByIds', expect.objectContaining({
        criteria: expectedCriteria,
        column: 'column'
      }));
    });
  });

  describe('getCaseCriteriasByIds$', () => {
    it('should call the right api with getCaseCriteriasByIds$', () => {
      const queryParams = {
        exampleQueryParams: 'test'
      };
      service.getCaseCriteriasByIds$({}, queryParams);
      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/searchByIds', expect.objectContaining({
        params: expect.objectContaining({
          params: JSON.stringify(queryParams)
        })
      }));
    });

    it('should build the expected criteria filter object', () => {
      const criteriaParams = {
        criteria: [{ id: 'id1' }, { id: 'id2' }]
      };

      const expectedCriteria = ['id1', 'id2'];

      service.getCaseCriteriasByIds$(criteriaParams, {});

      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/searchByIds', expect.objectContaining({
        params: expect.objectContaining({ q: JSON.stringify(expectedCriteria) })
      }));
    });
  });

  describe('validateCaseCharacteristics$', () => {
    it('should call the right api with validateCaseCharacteristics$', () => {
      httpMock.get.mockReturnValue(of({}));
      service.validateCaseCharacteristics$({ value: {} } as any, 'E');
      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/characteristics/validateCharacteristics', {
        params: expect.objectContaining({ criteria: JSON.stringify({}) })
      });
    });

    it('should build the expected criteria filter object', () => {
      const criteriaParams = {
        caseType: { code: 'caseTypeCode' },
        caseCategory: { code: 'caseCategoryCode' },
        program: { key: 'caseCategoryKey' },
        jurisdiction: { code: 'jurisdictionCode' },
        propertyType: { code: 'propertyTypeCode' },
        subType: { code: 'subTypeCode' },
        basis: { code: 'basisCode' },
        office: { key: 'officeKey' },
        profile: { code: 'profileCode' },
        protectedCriteria: true,
        criteriaNotInUse: true,
        matchType: 'matchType'
      };

      const expectedCriteria = {
        caseType: criteriaParams.caseType.code,
        caseCategory: criteriaParams.caseCategory.code,
        caseProgram: criteriaParams.program.key,
        jurisdiction: criteriaParams.jurisdiction.code,
        propertyType: criteriaParams.propertyType.code,
        subType: criteriaParams.subType.code,
        basis: criteriaParams.basis.code,
        office: criteriaParams.office.key,
        profile: criteriaParams.profile.code,
        includeProtectedCriteria: criteriaParams.protectedCriteria,
        includeCriteriaNotInUse: criteriaParams.criteriaNotInUse,
        matchType: criteriaParams.matchType
      };
      httpMock.get.mockReturnValue(of(new SearchResult()));
      const form = {
        value: criteriaParams,
        controls: {}
      };
      service.validateCaseCharacteristics$(form as any, 'W');

      expect(httpMock.get.mock.calls[0][0]).toBe('api/configuration/rules/characteristics/validateCharacteristics');
      expect(httpMock.get.mock.calls[0][1].params).toEqual({criteria: JSON.stringify(expectedCriteria), purposeCode: 'W'});
    });

  });

});
