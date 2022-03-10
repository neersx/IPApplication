import { BehaviorSubject, Observable, of } from 'rxjs';
import { ConnectionResponseModel } from './dms-integration.service';

export class DmsIntegrationServiceMock {
    hasPendingChanges$ = new Observable<boolean>();
    hasPendingDatabaseChanges$ = new BehaviorSubject(false);
    hasErrors$ = new Observable<boolean>();
    save$ = jest.fn().mockReturnValue(of({}));
    sendAllToDms$ = jest.fn(() => of({}));
    acknowledge$ = jest.fn(() => of({}));
    validateUrl$ = jest.fn(() => of(true));
    private readonly testResponse = new ConnectionResponseModel();
    constructor() {
        this.testResponse.success = true;
    }
    testConnections$ = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    raisePendingChanges = jest.fn();
    raiseHasErrors = jest.fn();
    getRequiresCredentials = jest.fn().mockReturnValue({});
    getManifest = jest.fn(() => of({}));
    getCredentials = jest.fn();
    testCaseWorkspace$ = jest.fn().mockReturnValue(Promise.resolve([]));
    testNameWorkspace$ = jest.fn().mockReturnValue(Promise.resolve([]));
    getDataDownload = jest.fn(() => of({}));
}