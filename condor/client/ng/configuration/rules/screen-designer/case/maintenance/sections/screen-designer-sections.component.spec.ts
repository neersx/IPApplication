import { ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { ScreenDesignerSectionsComponent } from './screen-designer-sections.component';

describe('ScreenDesignerSectionsComponent', () => {
  let component: ScreenDesignerSectionsComponent;
  let cdRef: ChangeDetectorRefMock;
  let mockService: any;
  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    mockService = { getCriteriaSections$: jest.fn().mockReturnValue({ pipe: jest.fn() }) };
    component = new ScreenDesignerSectionsComponent(mockService, new TranslateServiceMock() as any, cdRef as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('buildGridOptions.read$', () => {
    it('should call getCriteriaSections$ in the read method for the criteria id', () => {
      component.ngOnInit();
      component.topic = { params: { viewData: { criteriaData: { id: 1 } } } } as any;

      component.gridoptions.read$({} as any);

      expect(mockService.getCriteriaSections$).toHaveBeenCalledWith(1);
    });

  });
});
