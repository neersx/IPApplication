import { Observable } from 'rxjs';

export class BulkUpdateServiceMock {
    applyBulkUpdateChanges = jest.fn().mockReturnValue(new Observable());
    hasRestrictedCasesForStatus = jest.fn().mockReturnValue(new Observable<boolean>());
    checkStatusPassword = jest.fn().mockReturnValue(new Observable<boolean>());
}