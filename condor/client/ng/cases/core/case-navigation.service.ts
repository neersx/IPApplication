import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { SelectedColumn } from 'search/presentation/search-presentation.model';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

export class SearchResult {
    rows: Array<any>;
    columns: Array<any>;
    totalRows: number;
}
@Injectable()
export class CaseNavigationService {
    private dict?: Array<any>;
    private totalRows: number;
    private lastSearch?: any;
    private selectedTopic: string;
    private returnFromCache = false;
    private loadedData: Array<{ skip: number, data: SearchResult }> = [];
    constructor(private readonly http: HttpClient) {
        this.init();
    }

    init(): void {
        this.dict = [];
        this.totalRows = 0;
        this.lastSearch = undefined;
        this.loadedData = [];
        this.returnFromCache = false;
    }

    tempReturnNextRecordSetFromCache(): void {
        this.returnFromCache = true;
    }

    getNavigationData(): { keys: Array<any>, totalRows: number, pageSize: number } {
        return {
            keys: this.dict,
            totalRows: this.totalRows,
            pageSize: this.lastSearch && this.lastSearch.params ? this.lastSearch.params.take : 0
        };
    }

    getCaseKeyFromRowKey(rowKey): Number {
        const keyValue = this.dict.find(item => item.key === rowKey);

        return keyValue ? keyValue.value : null;
    }

    getSearch$(lastSearch: any): Observable<SearchResult> {
        if (this.returnFromCache) {
            this.returnFromCache = false;
            const caseData = this.loadedData.find(d => d.skip === lastSearch.params.skip);
            if (caseData) {
                return of(caseData.data);
            }
        }
        if (lastSearch.queryKey) {

            return this.savedSearch$(lastSearch.queryKey, lastSearch.params, null, lastSearch.queryContext);
        }

        return this.search$(lastSearch.criteria, lastSearch.params, lastSearch.queryContext)
            .pipe(this.setNavigationData(lastSearch.criteria, lastSearch.params, null, lastSearch.queryContext));
    }

    setNavigationData = (filter?, params?: GridQueryParameters, queryKey?: number, queryContext?: Number) => map((data: SearchResult) => {
        this.lastSearch = { criteria: filter, params, queryKey, queryContext };
        this.totalRows = data.totalRows;
        this.createRowKeyItemKeyMappings(data, params.skip);
        this.loadedData.push({ skip: params.skip, data });
        this.setSelectedTopic(undefined);

        return data;
    });

    fetchNext$(currentIndex: number): Observable<Array<any>> {
        // tslint:disable-next-line: strict-boolean-expressions
        const indexNumber = Number(currentIndex) || 0;
        const lastPageIndex = Math.floor(indexNumber / this.lastSearch.params.take);
        this.lastSearch.params.skip = lastPageIndex * this.lastSearch.params.take;

        return this.getSearch$(this.lastSearch).pipe(map(x => {
            return this.dict;
        }));
    }
    getCurrentPageIndex(rowKey: string): number {
        let skip = 0;
        const data = this.loadedData.find(d => d.data.rows.find(r => r.rowKey === rowKey));
        if (data) {
            skip = data.skip;
        }

        return (skip / this.lastSearch.params.take) + 1;
    }

    savedSearch$(queryKey: number, qparams: any, selectedColumns: Array<SelectedColumn>, queryContext?: Number): Observable<any> {
        const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

        return this.http.post(
            `${baseApiRoute}savedSearch`, {
            queryKey,
            params: qparams,
            selectedColumns,
            queryContext
        }
        ).pipe(
            this.setNavigationData(null, qparams, queryKey, queryContext)
        );
    }

    getSelectedTopic(): string {
        return this.selectedTopic;
    }

    setSelectedTopic(topicKey: string): void {
        this.selectedTopic = topicKey ? topicKey.split('_')[0] : undefined;
    }

    private search$(filter, params: GridQueryParameters, queryContext: Number): Observable<any> {
        const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;

        return this.http
            .post(baseApiRoute, {
                criteria: filter,
                params,
                queryContext
            }).pipe(this.setNavigationData(filter, params, null, queryContext));
    }
    private createRowKeyItemKeyMappings(data: SearchResult, skipCount: number): any {
        const dict = [];
        if (data && data.rows) {
            data.rows.forEach(element => {
                dict.push({
                    key: element.rowKey.toString(),
                    value: element.caseKey
                });
                element.rowKey = element.rowKey.toString();
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

    clearLoadedData = (): void => {
        this.loadedData.splice(0);
        this.dict.splice(0);
    };
}