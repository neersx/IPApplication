import { of } from 'rxjs/internal/observable/of';

export class TimeRecordingTimerGlobalServiceMock {
    timeFormat = 'HH:mm:ss';
    checkCurrentRunningTimers = jest.fn().mockReturnValue(of());
    stopTimer = jest.fn().mockReturnValue(of());
    startTimerForCase = jest.fn();
}