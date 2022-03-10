import { Observable } from 'rxjs';

export class EventNoteDetailServiceMock {
    getEventNotesDetails$ = jest.fn().mockReturnValue(new Observable());
    getEventNoteTypes$ = jest.fn().mockReturnValue(new Observable());
    maintainEventNotes = jest.fn().mockReturnValue(new Observable());
    isPredefinedNoteTypeExist = jest.fn().mockReturnValue(new Observable());
    viewDataFormatting = jest.fn().mockReturnValue(new Observable());
    getDefaultAdhocInfo$ = jest.fn().mockReturnValue(new Observable());
}