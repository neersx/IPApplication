import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { EventNoteViewData } from 'portfolio/event-note-details/event-notes.model';
import { Observable } from 'rxjs';
import { CommonSearchParams, GridNavigationService, SearchResult } from 'shared/shared-services/grid-navigation.service';
import { ActionEventsRequestModel } from './action-model';
import { ActionViewData } from './action-view-data.model';

@Injectable()
export class CaseViewActionsService {

    constructor(private readonly http: HttpClient, private readonly navigationService: GridNavigationService) {
        this.navigationService.init(this.searchMethod, 'eventNo');
    }

    getViewData$ = (caseKey: number): Observable<ActionViewData> => {
        return this.http.get<ActionViewData>('api/case/action/view/' + caseKey);
    };

    private readonly searchMethod = (lastSearch: CommonSearchParams): Observable<SearchResult> => {
        const q: ActionEventsRequestModel = {
            criteria: lastSearch.criteria,
            params: lastSearch.params
        };

        return this.getActionEvents$(q);
    };

    getActions$ = (caseKey: number, importanceLevel: number, includeOpenActions: boolean, includeClosedActions: boolean,
        includePotentialActions: boolean, queryParams: any): Observable<any> => {
        return this.http.get('api/case/' + caseKey + '/action', {
            params: {
                q: JSON.stringify({
                    importanceLevel,
                    includeOpenActions,
                    includeClosedActions,
                    includePotentialActions
                }),
                params: JSON.stringify(queryParams)
            }
        });
    };

    getActionEvents$ = (q: ActionEventsRequestModel): Observable<any> => {
        return this.http.get('api/case/' + q.criteria.caseKey + '/action/' + q.criteria.actionId, {
            params: {
                q: JSON.stringify({
                    cycle: q.criteria.cycle,
                    criteriaId: q.criteria.criteriaId,
                    importanceLevel: q.criteria.importanceLevel,
                    isCyclic: q.criteria.isCyclic,
                    AllEvents: q.criteria.isAllEvents,
                    MostRecent: q.criteria.isMostRecentCycle
                }),
                params: JSON.stringify(q.params)
            }
        }).pipe(this.navigationService.setNavigationData(q.criteria, q.params));
    };

    siteControlId(): Observable<number> {
        return this.http.get<number>('api/case/eventNotesDetails/siteControlId');
    }
}