import { ChangeDetectorRefMock, EventEmitterMock } from 'mocks';
import { SearchByCriteriaComponent } from './search-by-criteria.component';

describe('SearchByCriteriaComponent', () => {
  let component: SearchByCriteriaComponent;

  beforeEach(() => {
    component = new SearchByCriteriaComponent({ setSearchData: jest.fn() } as any, new ChangeDetectorRefMock() as any);
    (component.search as any) = new EventEmitterMock();
    (component.clear as any) = new EventEmitterMock();
    component.stateParams = { isLevelUp: true, rowKey: null };
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

  describe('ngOnInit', () => {
    it('should call resetFormData', () => {
      component.resetFormData = jest.fn();
      component.ngOnInit();

      expect(component.resetFormData).toHaveBeenCalled();
    });
  });

  describe('resetFormData', () => {
    it('should clear form data and emit that it has cleared', () => {
      component.resetFormData();

      expect(component.formData).toEqual({});
      expect(component.clear.emit).toHaveBeenCalled();
    });
  });
});
