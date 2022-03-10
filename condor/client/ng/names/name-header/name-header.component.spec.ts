import { ChangeDetectorRefMock } from 'mocks';
import { NameHeaderComponent } from './name-header.component';

describe('NameHeaderComponent', () => {
  let component: NameHeaderComponent;
  let serviceMock: {
    getHeader: jest.Mock
  };
  let cdr: ChangeDetectorRefMock;
  beforeEach(() => {
    serviceMock = {
      getHeader: jest.fn().mockReturnValue(Promise.resolve('test'))
    };
    cdr = new ChangeDetectorRefMock();
    component = new NameHeaderComponent(serviceMock as any, cdr as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should call service to get header values and mark for check', () => {
      component.nameKey = 100;
      component.ngOnInit();

      expect(serviceMock.getHeader).toHaveBeenCalledWith(100);
      serviceMock.getHeader().then(header => {
        expect(cdr.markForCheck).toHaveBeenCalled();
        expect(component.header).toEqual('test');
      });
    });
  });
});
