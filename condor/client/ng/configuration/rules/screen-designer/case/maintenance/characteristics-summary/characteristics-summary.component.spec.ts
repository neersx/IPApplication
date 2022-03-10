import { ChangeDetectorRefMock } from 'mocks';
import { CharacteristicsSummaryComponent } from './characteristics-summary.component';

describe('CharacteristicsSummaryComponent', () => {
  let component: CharacteristicsSummaryComponent;
  let cdRef: ChangeDetectorRefMock;
  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    component = new CharacteristicsSummaryComponent({ initFormData: jest.fn() } as any, {} as any, cdRef as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should initialise appropriate fields and call change detection', () => {
      component.topic = {
        params: {
          viewData: {
            viewData: 'viewData',
            criteriaData: 'criteriaData'
          }
        }
      } as any;

      component.ngOnInit();

      expect(component.formData).toEqual('criteriaData');
      expect(component.viewData).toEqual('viewData');
      expect(cdRef.markForCheck).toHaveBeenCalled();
    });
  });
});
