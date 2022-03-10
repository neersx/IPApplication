import { Injectable } from '@angular/core';
import { of } from 'rxjs';

@Injectable()
export class DmsServiceMock {
    getApiWithType$ = jest.fn().mockReturnValue(of({}));
    getDmsFolders$ = jest.fn().mockReturnValue(of({}));
    getDmsChildFolders$ = jest.fn().mockReturnValue(of({}));
    getDmsDocuments$ = jest.fn(() => of({}));
    getDmsDocumentDetails$ = jest.fn(() => of({}));
    getViewData$ = jest.fn(() => of({}));
    loginDms = jest.fn(() => of({}).toPromise());
    disconnectBindings = jest.fn();
}
