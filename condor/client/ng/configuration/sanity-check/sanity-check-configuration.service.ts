import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { SearchResult } from 'cases/core/case-navigation.service';
import { Observable } from 'rxjs/internal/Observable';
import { tap } from 'rxjs/operators';
import { CommonSearchParams, GridNavigationService } from 'shared/shared-services/grid-navigation.service';
@Injectable()
export class SanityCheckConfigurationService {
    constructor(private readonly http: HttpClient, private readonly gridNavService: GridNavigationService) {
        this.gridNavService.init(this.searchMethod as any, 'id');
    }

    private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<SearchResult> => {
        return this.search$(lastSearch.criteria.matchType, lastSearch.criteria.model, lastSearch.params);
    };

    setSearchData = (key: string, data: any) => {
        this.gridNavService.searchData[key] = data;
    };

    getSearchData = (key: string): any => {
        return this.gridNavService.searchData[key];
    };

    getNavData = () => this.gridNavService.getNavigationData();

    getViewData$(matchType: string): Observable<any> {
        return this.http.get<any>(`api/configuration/sanity-check/view-data/${matchType}`);
    }

    search$(matchType: string, model: any, queryParams: any): Observable<any> {
        return this.http.get<any>(`api/configuration/sanity-check/${matchType}/search`, {
            params: {
                criteria: JSON.stringify(model),
                params: JSON.stringify(queryParams)
            }
        }).pipe(this.gridNavService.setNavigationData({ matchType, model }, queryParams));
    }

    deleteSanityCheck$(matchType: 'case' | 'name', ids: Array<any>): Observable<any> {
        return this.http.delete<boolean>(`api/configuration/sanity-check/maintenance/${matchType}`, {
            params: { ids: JSON.stringify(ids) }
        });
    }
}

export class DataValidationSearchModel {
    activityId?: number;
    sequenceNo?: number;
    activityCategoryId: string;
    activityDate?: Date;
    activityType: string;
    attachmentName: string;
    attachmentType: string;
    eventCycle: number;
    eventId: string;
    filePath: string;
    isPublic?: boolean | false;
    language: string;
    pageCount: number;
    priorArtId?: number;

    constructor(data?: any) {
        return Object.assign(this, data);
    }
}
