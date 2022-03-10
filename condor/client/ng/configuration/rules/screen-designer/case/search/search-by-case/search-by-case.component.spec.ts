import { CaseValidCombinationServiceMock, ChangeDetectorRefMock, EventEmitterMock } from 'mocks';
import { of } from 'rxjs';
import { criteriaPurposeCode } from '../search.service';
import { SearchByCaseComponent } from './search-by-case.component';

describe('SearchByCaseComponent', () => {
  let component: SearchByCaseComponent;
  let validCombinationsMock: CaseValidCombinationServiceMock;
  let searchService: any;
  let cdRef: ChangeDetectorRefMock;
  beforeEach(() => {
    validCombinationsMock = new CaseValidCombinationServiceMock();
    searchService = {
      setSearchData: jest.fn(),
      getCaseCharacteristics$: jest.fn().mockReturnValue(of(null))
    };
    cdRef = new ChangeDetectorRefMock();
    component = new SearchByCaseComponent(validCombinationsMock as any, searchService, cdRef as any);
    (component.search as any) = new EventEmitterMock();
    (component.clear as any) = new EventEmitterMock();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('submitForm', () => {
    it('should emit the current form value', () => {
      (component.form as any) = { value: { test: 'value' } };
      component.formData = { test: 'value' };

      component.submitForm();

      expect(searchService.setSearchData).toHaveBeenCalledWith('caseSearchForm', component.formData);
      expect(component.search.emit).toHaveBeenCalledWith({ test: 'value' });
    });
  });

  describe('onCaseChange', () => {
    it('should do nothing on null call', () => {
      component.onCaseChange(null);
      expect(searchService.getCaseCharacteristics$).not.toHaveBeenCalled();
    });

    it('should do nothing on empty key', () => {
      component.onCaseChange({ key: null });
      expect(searchService.getCaseCharacteristics$).not.toHaveBeenCalled();
    });

    it('should call getCaseCharacteristics$ with the right params', () => {
      component.onCaseChange({ key: 1 });
      expect(searchService.getCaseCharacteristics$).toHaveBeenCalledWith(1, criteriaPurposeCode.ScreenDesignerCases);
    });

    it('should set the correct values on successful return from server', () => {
      const serverValue = {
        jurisdiction: 'jurisdiction',
        basis: 'basis',
        caseCategory: 'caseCategory',
        caseType: 'caseType',
        office: 'office',
        program: 'program',
        propertyType: 'propertyType',
        subType: 'subType'
      };
      searchService.getCaseCharacteristics$.mockReturnValue(of(serverValue));

      component.onCaseChange({ key: 1 });

      expect(component.formData).toEqual(expect.objectContaining(serverValue));
    });
  });
});
