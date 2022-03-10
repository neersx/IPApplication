import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { ActionEventsRequestModel } from '../actions/action-model';
import { CaseViewActionsService } from '../actions/case-view.actions.service';
import { EventRulesDetailsModel, EventRulesRequest } from './event-rule-details.model';

@Injectable()
export class EventRuleDetailsService {
    baseEventUrl = 'api/case/eventRules/';
    constructor(private readonly http: HttpClient, private readonly actionsService: CaseViewActionsService, private readonly navigationService: GridNavigationService) {
    }

    getEventDetails$ = (eventRuleRequest: EventRulesRequest): Observable<EventRulesDetailsModel> => {
        return this.http.get<EventRulesDetailsModel>(this.baseEventUrl + 'getEventRulesDetails', {
            params: {
                q: JSON.stringify(eventRuleRequest)
            }
        });
    };

}