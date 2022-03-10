
import { CaseValidCombinationServiceMock, EventEmitterMock } from 'mocks';
import { SearchByCharacteristicComponent } from './search-by-characteristic.component';

describe('SearchByCharacteristicComponent', () => {
  let component: SearchByCharacteristicComponent;
  let validCombinationService: CaseValidCombinationServiceMock;
  beforeEach(() => {
    validCombinationService = new CaseValidCombinationServiceMock();
    component = new SearchByCharacteristicComponent(validCombinationService as any, { setSearchData: jest.fn() } as any);
    component.stateParams = { rowKey: null, isLevelUp: true };
    (component.search as any) = new EventEmitterMock();
    (component.clear as any) = new EventEmitterMock();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('submitForm', () => {
    it('should emit the current form value', () => {
      (component.form as any) = { value: { test: 'value' } };

      component.submitForm();

      expect(component.search.emit).toHaveBeenCalledWith({ test: 'value' });
    });
  });

  describe('resetFormData', () => {
    it('should default the form data back to the expected values', () => {
      (component.viewData as any) = { canMaintainProtectedRules: true };
      component.formData = {
        includeProtectedCriteria: false,
        matchType: 'not-exact-match'
      };
      (validCombinationService as any).validCombinationDescriptionsMap = 'validCombinationDescriptionsMap';
      (validCombinationService as any).extendValidCombinationPickList = 'extendValidCombinationPickList';

      component.resetFormData();

      expect(component.formData.includeProtectedCriteria).toBeTruthy();
      expect(component.picklistValidCombination).toEqual('validCombinationDescriptionsMap');
      expect(component.extendPicklistQuery).toEqual('extendValidCombinationPickList');
      expect(component.formData.matchType).toEqual('exact-match');
      expect(component.clear.emit).toHaveBeenCalled();
      expect(validCombinationService.initFormData).toHaveBeenCalled();
    });
  });
});
