import { of } from 'rxjs';
import { delay } from 'rxjs/operators';

export class TimerServiceMock {
    getDefaultNarrativeFromActivityVal: any;
    checkCurrentRunningTimersVal: any;
    startTimerForVal: any;
    saveTimerVal: any;
    stopTimerVal: any;
    resetTimerVal: any;
    deleteTimerVal: any;
    timeFormat = 'HH:mm:ss';

    constructor() {
        this.getDefaultNarrativeFromActivityVal = null;
        this.startTimerForVal = null;
        this.saveTimerVal = null;
        this.stopTimerVal = null;
        this.resetTimerVal = null;
        this.deleteTimerVal = null;
    }

    checkCurrentRunningTimers = jest.fn().mockImplementation(() => { return of(this.checkCurrentRunningTimersVal); });
    startTimerFor = jest.fn().mockImplementation(() => { return of(this.startTimerForVal).pipe(delay(this.delayVal)); });
    saveTimer = jest.fn().mockImplementation(() => { return of(this.saveTimerVal).pipe(delay(this.delayVal)); });
    stopTimer = jest.fn().mockImplementation(() => { return of(this.stopTimerVal).pipe(delay(this.delayVal)); });
    resetTimer = jest.fn().mockImplementation(() => { return of(this.resetTimerVal).pipe(delay(this.delayVal)); });
    deleteTimer = jest.fn().mockImplementation(() => { return of(this.deleteTimerVal).pipe(delay(this.delayVal)); });

    delayVal = 500;
}

export class TimerModalServiceMock {
    getDefaultNarrativeFromActivityVal: any;
    delayVal = 500;

    constructor() {
        this.getDefaultNarrativeFromActivityVal = null;
    }
    getDefaultNarrativeFromActivity = jest.fn().mockImplementation(() => { return of(this.getDefaultNarrativeFromActivityVal).pipe(delay(this.delayVal)); });

}