import { of } from 'rxjs';
import { CommonSearchParams, GridNavigationService, SearchResult } from './grid-navigation.service';

describe('GridNavigationService', () => {
  let service: GridNavigationService;
  beforeEach(() => {
    service = new GridNavigationService();
  });
  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('init', () => {
    it('should set the search method and the id field, and clear all local members', () => {
      const searchMethod = (lastSearch: CommonSearchParams) => of(new SearchResult());
      const idField = 'idField';

      service.init(searchMethod, idField);

      expect((service as any).searchMethod).toEqual(searchMethod);
      expect((service as any).idField).toEqual(idField);
      expect((service as any).dict).toEqual([]);
      expect((service as any).totalRows).toEqual(0);
      expect((service as any).loadedData).toEqual([]);
      expect((service as any).returnFromCache).toEqual(false);
      expect((service as any).lastSearch).toBeUndefined();
    });
  });

  describe('temporarilyReturnNextRecordSetFromCache', () => {
    it('should set cache to true', () => {
      expect((service as any).returnFromCache).toBeFalsy();

      service.temporarilyReturnNextRecordSetFromCache();

      expect((service as any).returnFromCache).toBeTruthy();
    });
  });

  describe('getNavigationData', () => {
    it('should return the private members as expected', () => {
      const localService = service as any;
      localService.dict = ['exampleRecord1', 'exampleRecord2'];
      localService.totalRows = 100;
      localService.lastSearch = { params: { take: 1000 } };

      const returnedData = service.getNavigationData();

      expect(returnedData.keys).toEqual(localService.dict);
      expect(returnedData.pageSize).toEqual(1000);
      expect(returnedData.totalRows).toEqual(100);
    });
  });
});
