import { AppContextServiceMock } from 'core/app-context.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { RecentCasesComponent } from './recent-cases.component';

describe('RecentCasesComponent', () => {
  let component: RecentCasesComponent;
  let contextService: AppContextServiceMock;
  let changeDetectorMock: ChangeDetectorRefMock;
  let localSettings: LocalSettingsMock;
  const dateServiceSpy = { getParseFormats: jest.fn(), culture: 'en-US', dateFormat: 'testFormat' };
  let serviceMock: { get: jest.Mock, getDefaultProgram: jest.Mock };
  beforeEach(() => {
    contextService = new AppContextServiceMock();
    changeDetectorMock = new ChangeDetectorRefMock();
    localSettings = new LocalSettingsMock();
    serviceMock = { get: jest.fn().mockReturnValue(of()), getDefaultProgram: jest.fn().mockReturnValue(of()) };
    component = new RecentCasesComponent(serviceMock as any, dateServiceSpy as any, contextService as any, changeDetectorMock as any, localSettings as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
  describe('ngOnInit', () => {
    it('should default the date format and the context from the date service', () => {
      component.ngOnInit();

      expect(component.dateFormat).toEqual(dateServiceSpy.dateFormat);
      expect(component.context).toEqual('recentCases');
      expect(component.expandSetting).toEqual(localSettings.keys.recentCases.expanded);
    });

    it('should default showWebLink to be true if can see in app context', () => {
      contextService.appContext = { user: { permissions: { canShowLinkforInprotechWeb: true } } };

      component.ngOnInit();

      expect(component.showWebLink).toBeTruthy();
    });

    it('should default showWebLink to be false if cant see in app context', () => {
      contextService.appContext = { user: { permissions: { canShowLinkforInprotechWeb: false } } };

      component.ngOnInit();

      expect(component.showWebLink).toBeFalsy();
    });
    it('should show recent cases to be false if cant see in app context', () => {
      contextService.appContext = { user: { permissions: { canViewRecentCases: false } } };
      spyOn(component, 'initializeRecentCases');
      component.ngOnInit();

      expect(component.initializeRecentCases).not.toBeCalled();
      expect(component.showRecentCases).toBeFalsy();
    });

    it('should show recent cases to be true if shows in app context', () => {
      contextService.appContext = { user: { permissions: { canViewRecentCases: true } } };
      spyOn(component, 'initializeRecentCases');
      component.ngOnInit();

      expect(component.initializeRecentCases).toBeCalled();
      expect(component.showRecentCases).toBeTruthy();
    });
  });

  describe('buildColumns', () => {
    it('should return empty if null passed in', () => {
      const cols = component.buildColumns({ columns: null } as any);

      expect(cols).toEqual([]);
    });

    it('should return empty if empty passed in', () => {
      const cols = component.buildColumns({ columns: [] } as any);

      expect(cols).toEqual([]);
    });

    it('should return mapped columns', () => {
      const columns = [
        {
          title: 'title1',
          id: 'id1',
          isHyperlink: true,
          format: 'format1',
          fieldId: 'fieldId1',
          filterable: true
        },
        {
          title: 'title2',
          id: 'id2',
          isHyperlink: false,
          format: 'format2',
          fieldId: 'fieldId2',
          filterable: false
        }
      ];

      const mappedColumns = component.buildColumns({ columns } as any);

      expect(mappedColumns.length).toEqual(2);
      expect(mappedColumns[0].title).toEqual(columns[0].title);
      expect(mappedColumns[0].templateExternalContext.id).toEqual(columns[0].id);
      expect(mappedColumns[0].templateExternalContext.isHyperlink).toEqual(columns[0].isHyperlink);
      expect(mappedColumns[0].templateExternalContext.format).toEqual(columns[0].format);
      expect(mappedColumns[0].sortable).toBeTruthy();
      expect(mappedColumns[0].field).toEqual(columns[0].fieldId);
      expect(mappedColumns[0].filter).toEqual(columns[0].filterable);

      expect(mappedColumns[1].title).toEqual(columns[1].title);
      expect(mappedColumns[1].templateExternalContext.id).toEqual(columns[1].id);
      expect(mappedColumns[1].templateExternalContext.isHyperlink).toEqual(columns[1].isHyperlink);
      expect(mappedColumns[1].templateExternalContext.format).toEqual(columns[1].format);
      expect(mappedColumns[1].sortable).toBeTruthy();
      expect(mappedColumns[1].field).toEqual(columns[1].fieldId);
      expect(mappedColumns[1].filter).toEqual(columns[1].filterable);
    });
  });

  describe('getdefaultProgram', () => {
    it('should set values if value returned', () => {
      const defaultProgramResponse = 'expectedResponse';
      serviceMock.getDefaultProgram.mockReturnValue(of(defaultProgramResponse));

      component.ngOnInit();

      serviceMock.getDefaultProgram().subscribe(() => {
        expect(component.defaultProgram).toEqual(defaultProgramResponse);
        expect(changeDetectorMock.markForCheck).toHaveBeenCalled();
      });
    });
  });

  describe('first get', () => {
    it('should initialise grid setting values if value returned', () => {
      const defaultProgramResponse = {
        columns: ['expectedColumns'],
        rows: ['expectedRows']
      };
      serviceMock.get.mockReturnValue(of(defaultProgramResponse));
      component.buildColumns = jest.fn();

      component.ngOnInit();

      serviceMock.get().subscribe(() => {
        expect(component.loaded).toBeTruthy();
        expect(component.responseColumns).toEqual(defaultProgramResponse.columns);
        expect(component.responseRows).toEqual(defaultProgramResponse.rows);
        expect(changeDetectorMock.markForCheck).toHaveBeenCalled();
      });
    });
  });

  describe('encodeLinkData', () => {
    it('should encode as expected', () => {
      const testOject = {
        test: 'value'
      };
      const encodedData = component.encodeLinkData(testOject);
      expect(encodedData).toContain(encodeURIComponent(JSON.stringify(testOject)));
    });
  });
});
