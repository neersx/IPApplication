import { Observable, of } from 'rxjs';

export class AdhocDateServiceMock {
    adhocDate = jest.fn().mockReturnValue(of({}));
    bulkFinalise = jest.fn().mockReturnValue(new Observable());
    finalise = jest.fn().mockReturnValue(new Observable());
}
