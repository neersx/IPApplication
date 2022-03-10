
import { IManageDataItemsComponent } from './i-manage-dataitems.component';

describe('IManageDataitemsComponent', () => {
  let component: IManageDataItemsComponent;
  let dmsService: {
    raisePendingChanges: jest.Mock,
    raiseHasErrors: jest.Mock
  };
  beforeEach(() => {
    dmsService = {
      raisePendingChanges: jest.fn(),
      raiseHasErrors: jest.fn()
    };
    component = new IManageDataItemsComponent(dmsService as any);
    component.topic = {
      params: {
        viewData: {

        }
      }
    } as any;
    component.form = {
      stausChanges: {
        subscribe: jest.fn()
      }
    } as any;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should return initialise correctly model', () => {
      (component as any).subscribeFormEvents = jest.fn();
      component.ngOnInit();
      component.caseSearch = 'test case search';
      component.nameSearch = 'test name search';

      const changes = component.topic.getDataChanges();

      expect(changes.dataItems).toEqual({
        caseSearch: component.caseSearch,
        nameSearch: component.nameSearch
      });
    });
  });
});
