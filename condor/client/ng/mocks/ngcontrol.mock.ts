import { Observable } from 'rxjs/internal/Observable';

export class NgControl {
    control = {
        statusChanges: new Observable(),
        markAsTouched: jest.fn()
    };
}