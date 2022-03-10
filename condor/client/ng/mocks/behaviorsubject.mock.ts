import { of } from 'rxjs';

export class BehaviorSubjectMock {
    getValue = jest.fn();
    next = jest.fn();
    asObservable = jest.fn().mockReturnValue(of({}));
    subscribe = jest.fn();
}