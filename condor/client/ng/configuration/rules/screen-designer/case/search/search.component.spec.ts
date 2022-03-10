import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock } from 'mocks';
import { ScreenDesignerSearchComponent } from './search.component';

describe('ScreenDesignerSearchComponent', () => {
  let component: ScreenDesignerSearchComponent;
  let mockSearchService: any;
  let mockLocalSettings: LocalSettingsMock;
  let mockChangeDetection: ChangeDetectorRefMock;
  beforeEach(() => {
    mockSearchService = {
      getCaseCriterias$: jest.fn(),
      getCaseCriteriasByIds$: jest.fn(),
      getColumnFilterData$: jest.fn(),
      getColumnFilterDataByIds$: jest.fn(),
      setSelectedSearchType: jest.fn(),
      getSelectedSearchType: jest.fn(),
      setRecentSearchCriteria: jest.fn()
    };
    mockChangeDetection = new ChangeDetectorRefMock();
    mockLocalSettings = new LocalSettingsMock();
    component = new ScreenDesignerSearchComponent(mockChangeDetection as any, mockSearchService, mockLocalSettings as any);
    component.viewData = {} as any;
    component.stateParams = {} as any;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
  describe('ngOnInit', () => {

    it('should call change detection on init and default settings to correct values', () => {
      component.ngOnInit();
      expect(component.matchType).toEqual('characteristic');
      expect(mockChangeDetection.detectChanges).toHaveBeenCalled();
      expect(component.searchGridOptions.columnSelection.localSetting).toEqual(mockLocalSettings.keys.screenDesigner.search.columnsSelection);
    });
  });

  describe('read$', () => {
    it('Should use the regular search method if match type not criteria with the correct parameters', () => {
      const testQueryParams = {
        skip: 0,
        take: 10
      };
      component.ngOnInit();
      component.criteria = 'test';
      component.matchType = 'not criteria';

      component.searchGridOptions.read$(testQueryParams);

      expect(mockSearchService.getCaseCriterias$).toHaveBeenCalledWith('not criteria', component.criteria, testQueryParams);
    });

    it('should call the id search if match type is criteria with correct parameters', () => {
      const testQueryParams = {
        skip: 0,
        take: 10
      };
      component.ngOnInit();
      component.criteria = 'test';
      component.matchType = 'criteria';
      component.searchGridOptions.read$(testQueryParams);

      expect(mockSearchService.getCaseCriterias$).toHaveBeenCalledWith('criteria', component.criteria, testQueryParams);
    });
  });

  describe('filterMetaData$', () => {
    it('should call the id meta data if match type is criteria with correct parameters', () => {
      component.ngOnInit();
      component.criteria = 'test';
      component.matchType = 'not criteria';
      component.queryParams = { test: 'value' };
      component.searchGridOptions.filterMetaData$({ field: 'testQueryParams' }, null);

      expect(mockSearchService.getColumnFilterData$).toHaveBeenCalledWith(component.criteria, 'testQueryParams', { test: 'value' });
    });

    it('should call the id meta data if match type is criteria with correct parameters', () => {
      component.ngOnInit();
      component.criteria = 'test';
      component.matchType = 'criteria';
      component.queryParams = { test: 'value' };
      component.searchGridOptions.filterMetaData$({ field: 'testQueryParams' }, null);

      expect(mockSearchService.getColumnFilterDataByIds$).toHaveBeenCalledWith(component.criteria, 'testQueryParams', { test: 'value' });
    });
  });

  describe('search', () => {
    beforeEach(() => {
      component.filter = {};
      component.searchResultsGrid = { dataOptions: { gridMessages: {} } as any, search: jest.fn(), clearFilters: jest.fn() } as any;
    });
    it('should clear filter on search being called', () => {
      component.search({ matchType: 'exact-match' });

      expect(component.filter).toBeNull();
      expect(component.criteria).toEqual({ matchType: 'exact-match' });
      expect(component.searchResultsGrid.dataOptions.gridMessages.noResultsFound).toEqual('noResultsFound');
      expect(component.searchResultsGrid.search).toHaveBeenCalled();
      expect(component.searchResultsGrid.clearFilters).toHaveBeenCalled();
    });

    it('should modify the no results found message if not exact match', () => {
      component.search({ matchType: 'not-exact-match' });

      expect(component.filter).toBeNull();
      expect(component.criteria).toEqual({ matchType: 'not-exact-match' });
      expect(component.searchResultsGrid.dataOptions.gridMessages.noResultsFound).toEqual('screenDesignerCases.search.noRecordsBestMatch');
      expect(component.searchResultsGrid.search).toHaveBeenCalled();
    });
  });

  describe('clear', () => {
    it('should call grid clear', () => {
      component.searchResultsGrid = { clear: jest.fn(), clearFilters: jest.fn() } as any;

      component.clear();

      expect(component.searchResultsGrid.clear).toHaveBeenCalled();
    });
  });
});
