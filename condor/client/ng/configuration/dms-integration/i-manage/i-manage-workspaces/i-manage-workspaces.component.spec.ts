import { ChangeDetectorRefMock } from 'mocks';
import { IManageWorkspacesComponent } from './i-manage-workspaces.component';

describe('IManageWorkspacesComponent', () => {
  let component: IManageWorkspacesComponent;

  let dmsService: {
    raisePendingChanges: jest.Mock,
    raiseHasErrors: jest.Mock
  };
  let cdr: ChangeDetectorRefMock;
  beforeEach(() => {
    dmsService = {
      raisePendingChanges: jest.fn(),
      raiseHasErrors: jest.fn()
    };
    cdr = new ChangeDetectorRefMock();
    component = new IManageWorkspacesComponent(dmsService as any, cdr as any, {} as any);
    (component as any).subscribeFormEvents = jest.fn();
    component.topic = {
      params: {
        viewData: {

        }
      }
    } as any;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should initialise case model from view data', () => {
      component.topic = {
        params: {
          viewData: {
            imanageSettings: {
              case: {
                test: 'testCase'
              }
            }
          }
        }
      } as any;
      component.ngOnInit();

      expect(component.case).toEqual({
        test: 'testCase'
      });
    });

    it('should initialise case model to object with default subtype if none on view data', () => {
      component.topic = {
        params: {
          viewData: {
            imanageSettings: {
            }
          }
        }
      } as any;
      component.ngOnInit();

      expect(component.case).toEqual({ subType: 'work' });
    });

    it('should initialise name model from view data', () => {
      component.topic = {
        params: {
          viewData: {
            imanageSettings: {
              nameTypes: [{
                test: 'testNames'
              }]
            }
          }
        }
      } as any;
      component.ngOnInit();

      expect(component.nameTypeClass).toEqual([{
        test: 'testNames'
      }]);
    });

    it('should initialise name model to empty array if none on view data', () => {
      component.topic = {
        params: {
          viewData: {
            imanageSettings: {
            }
          }
        }
      } as any;
      component.ngOnInit();
      expect(component.nameTypeClass).toEqual([]);
    });
  });
});
