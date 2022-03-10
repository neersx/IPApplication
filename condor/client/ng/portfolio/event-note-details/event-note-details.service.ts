import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { EventNotesData, EventNoteViewData } from './event-notes.model';

@Injectable()
export class EventNoteDetailsService {
    constructor(private readonly http: HttpClient) { }

    getEventNotesDetails$(taskPlannerRowKey: string): Observable<any> {
        return this.http.get('api/case/eventNotesDetails', {
            params: new HttpParams()
                .set('taskPlannerRowKey', taskPlannerRowKey ? taskPlannerRowKey : '')
        });
    }

    getDefaultAdhocInfo$(taskPlannerRowKey: string): Observable<any> {
        return this.http.get('api/case/default-adhoc-info', {
            params: new HttpParams()
                .set('taskPlannerRowKey', taskPlannerRowKey)
        });
    }

    getEventNoteTypes$(): Observable<any> {
        return this.http.get('api/case/event-note-types');
    }

    maintainEventNotes(eventNote: EventNotesData): Observable<any> {
        return this.http.post('api/case/eventNotesDetails/update',
            eventNote
        );
    }

    viewDataFormatting(): Observable<EventNoteViewData> {
        return this.http.get<EventNoteViewData>('api/case/eventNotesDetails/viewData/formatting');
    }
}