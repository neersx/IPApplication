import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject, Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { CommonSearchParams, GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { RoleSearch } from './roles.model';

@Injectable()
export class RoleSearchService {
  _baseUri = 'api/roles';
  _previousStateParam$ = new BehaviorSubject(null);
  _roleName$ = new BehaviorSubject(null);
  _lastTaskSearch: any;
  _lastModuleSearch: any;
  inUseRoles: Array<number> = [];
  _lastSearchCriteria: any;
  _lastQueryParams: any;
  selectedTopic: string;

  constructor(private readonly http: HttpClient, private readonly navigationService: GridNavigationService, private readonly localSettings: LocalSettings) {
    this.navigationService.init(this.searchMethod, 'roleId');
  }

  private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<any> => {
    const q: any = {
      criteria: lastSearch.criteria,
      params: lastSearch.params
    };

    return this.runSearch(q.criteria, q.params);
  };

  getRolesViewData(): Observable<any> {
    return this.http
      .get<any>(this._baseUri + '/viewdata/')
      .pipe(map((response: any) => {
        return response;
      }));
  }

  protectedRoles(): Array<any> {
    return [{ roleId: -20, roleName: 'user' }, { roleId: -21, roleName: 'internal' }, { roleId: -22, roleName: 'external' }];
  }

  setSelectedTopic(topicKey: string): void {
    this.selectedTopic = topicKey;
  }

  runSearch(searchCriteria: any, queryParams: any): Observable<any> {
    const searchParams = {
      q: JSON.stringify(searchCriteria),
      params: JSON.stringify(queryParams)
    };

    return this.http.get<any>(`${this._baseUri}/` + 'search', {
      params: { ...searchParams }
    }).pipe(map((res => {
      this.localSettings.keys.navigation.searchCriteria.setLocal(searchCriteria);
      this.localSettings.keys.navigation.queryParams.setLocal(queryParams);
      this.localSettings.keys.navigation.ids.setLocal(res.ids);

      return res.roles;
    })), this.navigationService.setNavigationData(searchCriteria, queryParams));
  }

  runFilterMetaSearch$ = (columnField: string, roleId?: number): Observable<any> => {
    return this.http.get<Array<any>>(`${this._baseUri}/search/filterData/column/${columnField}/role/${roleId}`, {
      params: { ...this._lastTaskSearch }
    });
  };

  runModuleFilterData$ = (columnField: string, roleId?: number): Observable<any> => {
    return this.http.get<Array<any>>(`${this._baseUri}/filterData/column/${columnField}/role/${roleId}`, {
      params: { ...this._lastModuleSearch }
    });
  };

  overviewDetails(roleId: number): Observable<any> {
    return this.http.get<any>(`${this._baseUri}/` + 'overview-details/' + roleId);
  }

  taskDetails(roleId: number, criteria: any, queryParams: any): Observable<any> {
    const searchParams = {
      q: JSON.stringify(criteria),
      params: JSON.stringify(queryParams)
    };

    return this.http.get<any>(`${this._baseUri}/` + 'task-details/' + roleId, {
      params: { ...searchParams }
    }).pipe(map((res: any) => {
      this._lastTaskSearch = searchParams;

      return res;
    }));
  }

  webPartDetails(roleId: number, queryParams: any): Observable<any> {
    const searchParams = {
      params: JSON.stringify(queryParams)
    };

    return this.http.get<any>(`${this._baseUri}/` + 'module-details/' + roleId, {
      params: { ...searchParams }
    }).pipe(map((res: any) => {
      this._lastModuleSearch = searchParams;

      return res;
    }));
  }

  subjectDetails(roleId: number): Observable<any> {
    return this.http.get<any>(`${this._baseUri}/` + 'subject-details/' + roleId);
  }

  deleteroles = (ids: Array<number>) => {
    return this.http.post(`${this._baseUri}/` + 'delete', {
      ids
    });
  };

  saveRole(overviewDetails: RoleSearch, opertaion: string, roleId = 0): Observable<any> {
    if (opertaion === RoleSearchState.DuplicateRole) {
      return this.http.post(`${this._baseUri}/` + 'copy/' + roleId, overviewDetails);
    } else if (opertaion === RoleSearchState.Adding || opertaion === RoleSearchState.Updating) {
      return this.http.post(`${this._baseUri}/` + 'create', overviewDetails);
    }
  }

  updateRoleDetails(rolesCollection: any): any {
    return this.http.post(`${this._baseUri}/` + 'update', rolesCollection);
  }

  markInUseRoles = (resultSet) => {
    _.each(resultSet, (role: any) => {
      _.each(this.inUseRoles, (inUseId) => {
        if (role.roleId === inUseId) {
          role.inUse = true;
          role.persisted = false;
          role.selected = true;
        }
      });
    });
  };

}

export enum PermissionItemState {
  added = 'Added',
  deleted = 'Deleted',
  modified = 'Modified'
}

export enum Permission {
  Grant = 1,
  Deny = 2,
  Clear = 0
}

export enum Action {
  All = 'all',
  Execute = 'execute',
  Insert = 'insert',
  Update = 'update',
  Delete = 'delete'
}

export enum ObjectTable {
  DataTopic = 'DATATOPIC',
  Task = 'TASK',
  Module = 'MODULE'
}

export enum RoleSearchState {
  Adding = 'adding',
  Updating = 'updating',
  DuplicateRole = 'duplicateRole'
}