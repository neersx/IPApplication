import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { NgForm } from '@angular/forms';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { CommonSearchParams, GridNavigationService, SearchResult } from 'shared/shared-services/grid-navigation.service';

@Injectable({
  providedIn: 'root'
})
export class SearchService {
  private matchType = 'characteristic';

  constructor(private readonly http: HttpClient, private readonly gridNavService: GridNavigationService) {
    this.gridNavService.init(this.searchMethod, 'id');
  }

  private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<SearchResult> => {
    return this.getCaseCriterias$(this.matchType, lastSearch.criteria, lastSearch.params);
  };

  temporarilyReturnNextRecordSetFromCache = () => {
    this.gridNavService.temporarilyReturnNextRecordSetFromCache();
  };

  getCurrentPageIndex = (rowKey: string) => {
    return this.gridNavService.getCurrentPageIndex(rowKey);
  };

  setSelectedSearchType = (page: string) => {
    this.setSearchData('selectedSearchType', page);
  };

  getSelectedSearchType = () => {
    return this.getSearchData('selectedSearchType');
  };

  getRecentSearchCriteria = () => {
    return this.getSearchData('recentSearchCriteria');
  };

  setRecentSearchCriteria = (criteria: any) => {
    this.setSearchData('recentSearchCriteria', criteria);
  };

  setSelectedTopic = (topic: string) => {
    this.setSearchData('selectedTopic', topic);
  };

  getSelectedTopic = () => {
    return this.getSearchData('selectedTopic');
  };

  setSearchData = (key: string, data: any) => {
    this.gridNavService.searchData[key] = data;
  };

  getSearchData = (key: string): any => {
    return this.gridNavService.searchData[key];
  };

  getNavData = () => this.gridNavService.getNavigationData();

  getCaseCriteriasData$ = (criteria: any, queryParams: any): Observable<any> => {
    return this.http.get('api/configuration/rules/screen-designer/case/viewData', {
      params: {
        q: JSON.stringify(criteria),
        params: JSON.stringify(queryParams)
      }
    });
  };

  getCaseCriteriasByIds$ = (criteria: any, queryParams: any): Observable<SearchResult> => {
    return this.http.get<SearchResult>('api/configuration/rules/screen-designer/case/searchByIds', {
      params: {
        q: JSON.stringify(this.getKeys(criteria, 'criteria', 'id') || []),
        params: JSON.stringify(queryParams)
      }
    }).pipe(this.gridNavService.setNavigationData(criteria, queryParams));
  };

  getColumnFilterData$(criteriaToParse: any, column, params): Observable<any> {
    const criteria = this.build(criteriaToParse);

    return this.http.post('api/configuration/rules/screen-designer/case/filterData', {
      criteria,
      params,
      column
    });
  }

  getColumnFilterDataByIds$(criteriaToParse: any, column, params): Observable<any> {
    const criteria = criteriaToParse ? this.getKeys(criteriaToParse, 'criteria', 'id') : null;

    return this.http.post('api/configuration/rules/screen-designer/case/filterDataByIds', {
      criteria,
      params,
      column
    });
  }

  getCaseCriterias$ = (matchType: string, criteria: any, queryParams: any): Observable<SearchResult> => {
    this.matchType = matchType;
    if (matchType === 'criteria') {
      return this.getCaseCriteriasByIds$(criteria, queryParams);
    }

    return this.getCaseCriteriasByCharacteristics$(criteria, queryParams);
  };

  getCaseCriteriasByCharacteristics$ = (criteria: any, queryParams: any): Observable<SearchResult> => {
    const c = this.build(criteria);

    return this.http.get<SearchResult>('api/configuration/rules/screen-designer/case/search', {
      params: {
        criteria: JSON.stringify(c),
        params: JSON.stringify(queryParams)
      }
    }).pipe(this.gridNavService.setNavigationData(criteria, queryParams));
  };

  private readonly build = (searchCriteria: any) => {
    if (searchCriteria == null) {
      return undefined;
    }

    return {
      caseType: this.getKey(searchCriteria, 'caseType', 'code'),
      caseCategory: this.getKey(searchCriteria, 'caseCategory', 'code'),
      caseProgram: this.getKey(searchCriteria, 'program', 'key'),
      jurisdiction: this.getKey(searchCriteria, 'jurisdiction', 'code'),
      propertyType: this.getKey(searchCriteria, 'propertyType', 'code'),
      subType: this.getKey(searchCriteria, 'subType', 'code'),
      basis: this.getKey(searchCriteria, 'basis', 'code'),
      office: this.getKey(searchCriteria, 'office', 'key'),
      profile: this.getKey(searchCriteria, 'profile', 'code'),
      checklist: this.getKey(searchCriteria, 'checklist', 'key'),
      includeProtectedCriteria: searchCriteria.protectedCriteria,
      includeCriteriaNotInUse: searchCriteria.criteriaNotInUse,
      matchType: searchCriteria.matchType
    };
  };

  private readonly getKey = (searchCriteria: any, propertyName: string, key: string) => {
    return searchCriteria[propertyName] && searchCriteria[propertyName][key];
  };
  private readonly getKeys = (searchCriteria: any, propertyName: string, key: string) => {
    return searchCriteria[propertyName] && searchCriteria[propertyName].map(item => item[key]);
  };

  getCaseCharacteristics$ = (caseKey: number, purposeCode: string): Observable<CaseValidCharacteristics> => {
    return this.http.get<CaseValidCharacteristics>(`api/configuration/rules/characteristics/caseCharacteristics/${caseKey}?purposeCode=${purposeCode}`);
  };

  validateCaseCharacteristics$ = (form: any, purposeCode: string, setDirty = true): Promise<CaseValidCharacteristics> => {
    const c = this.build(form.value ?? form);

    return this.http.get<CaseValidCharacteristics>('api/configuration/rules/characteristics/validateCharacteristics', {
      params: {
        purposeCode,
        criteria: JSON.stringify(c)
      }
    }).toPromise().then(validationResult => {
      Object.keys(validationResult).forEach(key => {
        if (form.controls[key]) {
          if (!validationResult[key].isValid) {
            form.controls[key].setValue(null);
          } else if (validationResult[key].key) {
            form.controls[key].setValue(validationResult[key]);
          }
          if (setDirty) {
            form.controls[key].markAsDirty();
            form.controls[key].markAsTouched();
          }
        }
      });

      return validationResult;
    });
  };
}

export class CaseValidCharacteristics {
  applyTo: string;
  basis: ValidCharacteristics;
  caseCategory: ValidCharacteristics;
  caseType: ValidCharacteristics;
  jurisdiction: ValidCharacteristics;
  office: ValidCharacteristics;
  program: ValidCharacteristics;
  propertyType: ValidCharacteristics;
  subType: ValidCharacteristics;
}

class ValidCharacteristics {
  isValid: boolean;
  key: string;
  value: string;
  code: string;
}

export const criteriaPurposeCode = {
  Workflows: 'E',
  ScreenDesignerCases: 'W',
  Checklists: 'C'
};
