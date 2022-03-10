import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { CaseValidateCharacteristicsCombinationService } from './case-validate-characteristics-combination.service';

describe('Service: CaseValidateCharacteristicsCombination', () => {
  let httpMock: HttpClientMock;
  let service: CaseValidateCharacteristicsCombinationService;
  beforeEach(() => {
    httpMock = new HttpClientMock();
    httpMock.get.mockReturnValue({
      // tslint:disable-next-line: no-empty
      pipe: (args: any) => { }
    });
    service = new CaseValidateCharacteristicsCombinationService(httpMock as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
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
      httpMock.get.mockReturnValue(of({}));
      const form = {
        value: criteriaParams,
        controls: {}
      };
      service.validateCaseCharacteristics$(form as any, 'W');

      expect(httpMock.get.mock.calls[0][0]).toBe('api/configuration/rules/characteristics/validateCharacteristics');
      expect(httpMock.get.mock.calls[0][1].params).toEqual({ criteria: JSON.stringify(expectedCriteria), purposeCode: 'W' });
    });

  });
});
