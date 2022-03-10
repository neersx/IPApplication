import { LocalSettingsMock } from 'core/local-settings.mock';
import { RelatedCasesComponent } from './related-cases.component';

describe('RelatedCasesComponent', () => {
  let component: RelatedCasesComponent;
  let localSettings: LocalSettingsMock;
  let service: {
    getRelatedCases(caseKey: number): any;
  };
  beforeEach(() => {
    service = {
      getRelatedCases: jest.fn()
    };
    localSettings = new LocalSettingsMock();
    component = new RelatedCasesComponent(localSettings as any, service as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should initialise the column configs correctly', () => {
      component.topic = {
        params: {
          ippAvailability: {
            file: {
              isEnabled: false,
              canView: false,
              canInstruct: false,
              hasViewAccess: false
            }
          }
        }
      } as any;
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).toEqual(['direction', 'relationship', 'internalReference', 'officialNumber', 'jurisdiction', 'eventDate', 'status', 'classes']);
    });

    it('should have client reference if isExternal', () => {
      component.topic = {
        params: {
          ippAvailability: {
            file: {
              isEnabled: false,
              canView: false,
              canInstruct: false,
              hasViewAccess: false
            }
          },
          isExternal: true
        }
      } as any;
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).toContain('clientReference');
    });

    it('should have isFiled if hasViewAccess and isEnabled', () => {
      component.topic = {
        params: {
          ippAvailability: {
            file: {
              isEnabled: true,
              canView: false,
              canInstruct: false,
              hasViewAccess: true
            }
          },
          isExternal: true
        }
      } as any;
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).toContain('isFiled');
    });

    it('should have isFiled if not hasViewAccess and isEnabled', () => {
      component.topic = {
        params: {
          ippAvailability: {
            file: {
              isEnabled: true,
              canView: false,
              canInstruct: false,
              hasViewAccess: false
            }
          },
          isExternal: true
        }
      } as any;
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).not.toContain('isFiled');
    });

    it('should have isFiled if hasViewAccess and not isEnabled', () => {
      component.topic = {
        params: {
          ippAvailability: {
            file: {
              isEnabled: false,
              canView: false,
              canInstruct: false,
              hasViewAccess: true
            }
          },
          isExternal: true
        }
      } as any;
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).not.toContain('isFiled');
    });

    it('should call the service on $read', () => {
      component.topic = {
        params: {
          viewData: {
            caseKey: 123
          }
        }
      } as any;

      (component.topic.params as any).ippAvailability = {
        file: {
          isEnabled: false,
          canView: false,
          canInstruct: false,
          hasViewAccess: false
        }
      };
      component.ngOnInit();
      const queryParams = 'test';
      component.gridOptions.read$(queryParams as any);

      expect(service.getRelatedCases).toHaveBeenCalledWith(123, queryParams);
    });
  });
});
