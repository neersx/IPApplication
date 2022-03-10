import { of } from 'rxjs';
import { CaseHeaderComponent } from './case-header.component';

describe('CaseHeaderComponent', () => {
  let component: CaseHeaderComponent;
  let service: {
    getHeader: jest.Mock
  };
  let cd: {
    markForCheck: jest.Mock
  };
  beforeEach(() => {
    service = {
      getHeader: jest.fn()
    };
    cd = {
      markForCheck: jest.fn()
    };
    component = new CaseHeaderComponent(service as any, cd as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should call getHeader', () => {
      component.caseKey = 123;
      const promise = Promise.resolve({ test: 'test' });
      service.getHeader.mockReturnValue(promise);
      component.ngOnInit();

      expect(service.getHeader).toHaveBeenCalledWith(123);
      promise.then(val => {
        expect(component.header).toEqual({ test: 'test' });
        expect(cd.markForCheck).toHaveBeenCalled();
      });
    });
  });
});
