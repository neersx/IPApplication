import { Observable } from 'rxjs';

export class SanityCheckResultServiceMock {
    getSanityCheckResults = jest.fn().mockReturnValue(new Observable<boolean>());
}