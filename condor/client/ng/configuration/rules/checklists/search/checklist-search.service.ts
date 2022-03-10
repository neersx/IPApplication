import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SearchResult } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { ChecklistConfigurationViewData } from '../checklists.models';

@Injectable({
    providedIn: 'root'
})

export class ChecklistSearchService {
    private matchType = 'characteristic';

    constructor(private readonly http: HttpClient) {
    }

    getCriteriaSearchViewData$(): Observable<any> {
        return this.http.get<ChecklistConfigurationViewData>('api/configuration/rules/checklist-configuration/view');
    }

    search$ = (matchType: string, criteria: any, queryParams: any): Observable<SearchResult> => {
        if (matchType === 'criteria') {
            return this.getChecklistCriteriasByIds$(criteria, queryParams);
        }

        return this.getCaseCriterias$(matchType, criteria, queryParams);
    };

    getCaseCriterias$ = (matchType: string, criteria: any, queryParams: any): Observable<SearchResult> => {
        this.matchType = matchType;

        return this.getCaseCriteriasByCharacteristics$(criteria, queryParams);
    };

    private readonly getCaseCriteriasByCharacteristics$ = (criteria: any, queryParams: any): Observable<SearchResult> => {
        const c = this.build(criteria);

        return this.http.get<SearchResult>('api/configuration/rules/checklist-configuration/search', {
            params: {
                criteria: JSON.stringify(c),
                params: JSON.stringify(queryParams)
            }
        });
    };

    getChecklistCriteriasByIds$ = (criteria: any, queryParams: any): Observable<SearchResult> => {
        return this.http.get<SearchResult>('api/configuration/rules/checklist-configuration/searchByIds', {
          params: {
            ids: JSON.stringify(_.pluck(criteria.criteria, 'id')),
            params: JSON.stringify(queryParams)
          }
        });
    };

    private readonly build = (searchCriteria: any) => {
        if (searchCriteria == null) {
            return undefined;
        }

        return {
            caseType: this.getKey(searchCriteria, 'caseType', 'code'),
            caseCategory: this.getKey(searchCriteria, 'caseCategory', 'code'),
            profile: this.getKey(searchCriteria, 'profile', 'key'),
            jurisdiction: this.getKey(searchCriteria, 'jurisdiction', 'code'),
            propertyType: this.getKey(searchCriteria, 'propertyType', 'code'),
            subType: this.getKey(searchCriteria, 'subType', 'code'),
            basis: this.getKey(searchCriteria, 'basis', 'code'),
            office: this.getKey(searchCriteria, 'office', 'key'),
            checklist: this.getKey(searchCriteria, 'checklist', 'key'),
            question: this.getKey(searchCriteria, 'question', 'key'),
            applyTo: searchCriteria.applyTo,
            includeProtectedCriteria: searchCriteria.includeProtectedCriteria,
            matchType: searchCriteria.matchType
        };
    };

    private readonly getKey = (searchCriteria: any, propertyName: string, key: string) => {
        return searchCriteria[propertyName] && searchCriteria[propertyName][key];
    };
}
