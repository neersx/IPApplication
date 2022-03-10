import { OfficialNumbersComponent } from './official-numbers.component';

describe('OfficialNumbersComponent', () => {
  let component: OfficialNumbersComponent;
  let service: {
    getCaseViewIpOfficeNumbers(caseKey: number, queryParams: any): any,
    getCaseViewOtherNumbers(caseKey: number, queryParams: any): any
  };
  beforeEach(() => {
    service = {
      getCaseViewIpOfficeNumbers: jest.fn(),
      getCaseViewOtherNumbers: jest.fn()
    };
    component = new OfficialNumbersComponent(service as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should set the right official number type', () => {
      component.topic = {
        params: {
          officialNumberType: 'test'
        }
      } as any;

      component.ngOnInit();

      expect(component.officialNumberType).toEqual('test');
    });

    it('should have the correct columns', () => {
      component.topic = {
        params: {
          officialNumberType: 'test'
        }
      } as any;

      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).toEqual(['numberTypeDescription', 'officialNumber', 'dateInForce', 'isCurrent']);
    });

    it('should call ipOffice search method', () => {
      component.topic = {
        params: {
          officialNumberType: 'ipOffice',
          viewData: {
            caseKey: 123
          }
        }
      } as any;
      const queryParams = {
        test: 'test'
      };

      component.ngOnInit();
      component.gridOptions.read$(queryParams as any);

      expect(service.getCaseViewIpOfficeNumbers).toHaveBeenCalledWith(123, queryParams);
    });

    it('should call ipOffice search method', () => {
      component.topic = {
        params: {
          officialNumberType: 'other',
          viewData: {
            caseKey: 123
          }
        }
      } as any;
      const queryParams = {
        test: 'test'
      };

      component.ngOnInit();
      component.gridOptions.read$(queryParams as any);

      expect(service.getCaseViewOtherNumbers).toHaveBeenCalledWith(123, queryParams);
    });
  });
});
