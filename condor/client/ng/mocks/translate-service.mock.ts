import { of } from 'rxjs';

export class TranslateServiceMock {
    instant = jest.fn(t => t);
    get = jest.fn(of);
    onSuccess = jest.fn();
}
