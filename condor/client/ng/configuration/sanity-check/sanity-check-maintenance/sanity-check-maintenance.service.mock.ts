import { Observable } from 'rxjs';
import { of } from 'rxjs/internal/observable/of';

export class SanityCheckMaintenanceServiceMock {
    save$ = jest.fn().mockReturnValue(of({}));
    update$ = jest.fn().mockReturnValue(of({}));
    hasPendingChanges$ = new Observable<boolean>();
    resetChangeEventState = jest.fn();
    hasErrors$ = new Observable<boolean>();
    raiseStatus = jest.fn();
}
