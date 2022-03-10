import { AppContextServiceMock } from 'core/app-context.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { BusMock } from 'mocks/bus.mock';
import { CriticalDatesComponent } from './critical-dates.component';

describe('CriticalDatesComponent', () => {
  let component: CriticalDatesComponent;
  let appContextService: AppContextServiceMock;
  let bus: BusMock;
  let localSettings: LocalSettingsMock;
  let service: {
    getDates(caseKey: number, queryParams: any): any
  };
  beforeEach(() => {
    appContextService = new AppContextServiceMock();
    bus = new BusMock();
    service = {
      getDates: jest.fn()
    };
    localSettings = new LocalSettingsMock();
    component = new CriticalDatesComponent(appContextService as any, bus as any, localSettings as any, service);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
  describe('ngOnDestroy', () => {
    it('should call unsubscribe', () => {
      (component as any).subscription = { unsubscribe: jest.fn() } as any;

      component.ngOnDestroy();

      expect((component as any).subscription.unsubscribe).toHaveBeenCalled();
    });
  });

  describe('ngOnInit', () => {
    it('should subscribe to correct event', () => {
      component.ngOnInit();

      expect(bus.channel).toHaveBeenCalledWith('policingCompleted');
    });

    it('should initialise the column configs correctly', () => {
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).toEqual(['isCpaRenewalDate', 'date', 'eventDescription', 'officialNumber']);
    });

    it('should call the service on $read', () => {
      component.topic = {
        params: {
          viewData: {
            caseKey: 123
          }
        }
      } as any;
      component.ngOnInit();
      const queryParams = 'test';
      component.gridOptions.read$(queryParams as any);

      expect(service.getDates).toHaveBeenCalledWith(123, queryParams);
    });
  });

  describe('reloadData', () => {
    it('should call the grid search method', () => {
      component.gridOptions = {
        _search: jest.fn()
      } as any;
      component.reloadData();

      expect(component.gridOptions._search).toHaveBeenCalled();
    });
  });
});
