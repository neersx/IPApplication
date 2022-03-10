import { Observable, of } from 'rxjs';

export class AttachmentConfigurationServiceMock {
    hasPendingChanges$ = new Observable<boolean>();
    hasErrors$ = new Observable<boolean>();
    save$ = jest.fn().mockReturnValue(of({}));
    validateUrl$ = jest.fn(() => of(true));
    raisePendingChanges = jest.fn();
    raiseHasErrors = jest.fn();
}