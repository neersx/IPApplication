import { Observable, of } from 'rxjs';

export class AttachmentPopupServiceMock {
    hideExcept = jest.fn();
    clearCache = jest.fn();
    getAttachments$: (caseId: number, eventNo: number, eventCycle: number) => Observable<any> = jest.fn(() => of({}));
}