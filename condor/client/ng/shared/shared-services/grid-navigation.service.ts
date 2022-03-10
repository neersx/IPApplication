import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

export class SearchResult {
  data: Array<any>;
  columns: Array<any>;
  pagination: {
    total: number
  };
}

export class CommonSearchParams {
  criteria: any;
  params: {
    skip: number,
    take: number
  };
  queryKey: any;
}

@Injectable()
export class GridNavigationService {
  private dict?: Array<any>;
  private totalRows: number;
  private lastSearch?: CommonSearchParams;
  private returnFromCache = false;
  private loadedData: Array<{ skip: number, data: SearchResult }> = [];
  private searchMethod: (lastSearch: CommonSearchParams) => Observable<SearchResult>;
  private idField: string;
  readonly searchData: { [key: string]: any };

  constructor() {
    this.searchData = {};
  }

  init(searchMethod: (lastSearch: CommonSearchParams) => Observable<SearchResult>, idField: string): void {
    this.dict = [];
    this.totalRows = 0;
    this.lastSearch = undefined;
    this.loadedData = [];
    this.returnFromCache = false;
    this.searchMethod = searchMethod;
    this.idField = idField;
  }

  temporarilyReturnNextRecordSetFromCache(): void {
    this.returnFromCache = true;
  }

  getNavigationData(): { keys: Array<any>, totalRows: number, pageSize: number, fetchCallback(currentIndex: number): Promise<Array<any>>; } {
    return {
      keys: this.dict,
      totalRows: this.totalRows,
      pageSize: this.lastSearch && this.lastSearch.params ? this.lastSearch.params.take : 0,
      fetchCallback: (currentIndex: number): any => {
        return this.fetchNext$(currentIndex).toPromise();
      }
    };
  }

  setNavigationData = (filter?, params?: GridQueryParameters, queryKey?: number) => map((data: any) => {
    this.lastSearch = { criteria: filter, params, queryKey };
    const gridData: any = data;
    this.totalRows = gridData.pagination ? gridData.pagination.total : gridData.length;
    const pagingEnabled: Boolean = gridData.pagination ? true : false;
    this.createRowKeyIdMappings(data, params.skip, pagingEnabled);
    this.loadedData.push({ skip: params.skip, data });

    return data;
  });

  getCurrentPageIndex(rowKey: string): number {
    let skip = 0;
    const data = this.loadedData.find(d => d.data.data.find(r => r.rowKey === rowKey));
    if (data) {
      skip = data.skip;
    }

    return (skip / this.lastSearch.params.take) + 1;
  }

  fetchNext$(currentIndex: number): Observable<Array<any>> {
    // tslint:disable-next-line: strict-boolean-expressions
    const indexNumber = Number(currentIndex) || 0;
    const lastPageIndex = Math.floor(indexNumber / this.lastSearch.params.take);
    this.lastSearch.params.skip = lastPageIndex * this.lastSearch.params.take;

    return this.getSearch$(this.lastSearch).pipe(map(x => {
      return this.dict;
    }));
  }

  private getSearch$(lastSearch: CommonSearchParams): Observable<SearchResult> {
    if (this.returnFromCache) {
      this.returnFromCache = false;
      const searchData = this.loadedData.find(d => d.skip === lastSearch.params.skip);
      if (searchData) {
        return of(searchData.data);
      }
    }

    return this.searchMethod(lastSearch);
  }

  private createRowKeyIdMappings(data: SearchResult, skipCount: number, pagingEnabled: Boolean): any {
    const dict = [];
    const gridData: any = pagingEnabled ? data.data : data;
    if (gridData) {
      gridData.forEach((element, index) => {
          dict.push({
            key: (index + skipCount + 1).toString(),
            value: element[this.idField].toString()
          });
          element.rowKey = (index + skipCount + 1).toString();
      });
      if (skipCount === 0) {
          this.dict = dict;
      } else {
          this.dict.push(...dict);
      }

      return this.dict;
    }

    return null;
  }

  clearLoadedData = () => {
    this.loadedData.splice(0);
    this.dict.splice(0);
  };
}
