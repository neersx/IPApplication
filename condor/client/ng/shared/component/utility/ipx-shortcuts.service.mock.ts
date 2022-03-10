import { of } from 'rxjs';
import { delay } from 'rxjs/operators';

export class IpxShortcutsServiceMock {
    observeMultiple$ = jest.fn().mockImplementation(() => {
        if (!!this.observeMultipleReturnValue) {

            return of(this.observeMultipleReturnValue).pipe(delay(this.interval));
        }

        return of();
    });
    observeMultipleReturnValue: any = null;
    interval = 500;
}