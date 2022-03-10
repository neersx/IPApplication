import { of } from 'rxjs';

export class BackgroundNotificationServiceMock {
    readMessages$ = jest.fn();
    setProcessIds = jest.fn();
    deleteProcessIds = jest.fn().mockReturnValue(of({}));
}