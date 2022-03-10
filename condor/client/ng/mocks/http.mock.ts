import { of } from 'rxjs';

export class HttpClientMock {
    get = jest.fn().mockReturnValue(of({}));
    post = jest.fn();
    put = jest.fn();
    delete = jest.fn();
    request = jest.fn();
}