import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { EventNoteDetailsService } from './event-note-details.service';

describe('due date case search modal', () => {
    let service: EventNoteDetailsService;
    let httpMock: any;

    beforeEach(() => {
        httpMock = new HttpClientMock();
        service = new EventNoteDetailsService(httpMock);
    });

    it('should create the service instance', async(() => {
        expect(service).toBeTruthy();
    }));

    it('should call the getEventNoteTypes method', async(() => {
        service.getEventNoteTypes$();
        expect(httpMock.get).toHaveBeenCalledWith('api/case/event-note-types');
        spyOn(httpMock, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));

    it('should call the maintainEventNotes method', async(() => {
        const response = {
            result: 'success'
        };
        const eventNote = { eventNoteType: 1, eventText: 'Data' } as any;
        httpMock.post.mockReturnValue(of(response));
        httpMock.post.mockReturnValue(of(response));
        service.maintainEventNotes(eventNote).subscribe(
            result => {
                expect(result).toBe(response);
            }
        );
        expect(httpMock.post).toHaveBeenCalledWith('api/case/eventNotesDetails/update', eventNote);
    }));
});