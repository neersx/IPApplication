import { TimeCalculationService } from './time-calculation.service';
import { TimeEntryEx } from './time-recording-model';
import { TimeRecordingServiceMock, TimeSettingsServiceMock } from './time-recording.mock';

let service: TimeCalculationService;
let timeService: any;
let timeSettings: any;

beforeEach(() => {
    timeService = new TimeRecordingServiceMock();
    timeSettings = new TimeSettingsServiceMock();

    service = new TimeCalculationService(timeService, timeSettings);
});
describe('Time Calculation Parse wrongly entered time', () => {
    it('should return null if entered time is HH:MM & display seconds is false', () => {
        timeSettings.displaySeconds = false;
        const parsedTime = service.parsePartiallyEnteredTime('HH:mm');
        expect(parsedTime).toBeNull();
    });
    it('should return null if entered time is HH:MM:ss & display seconds is true', () => {
        timeSettings.displaySeconds = true;
        service.selectedDate = new Date();
        const parsedTime = service.parsePartiallyEnteredTime('HH:mm:ss');
        expect(parsedTime).toBeNull();
    });
    it('should return null if entered time is HH:MM & display seconds is true, resulting in 00:00', () => {
        timeSettings.displaySeconds = true;
        timeSettings.is12HourFormat = false;
        service.selectedDate = new Date();
        const parsedTime = service.parsePartiallyEnteredTime('HH:mm');
        expect(parsedTime).toBeNull();
    });
    it('should set the mins to 00 when time entered only has valid hours', () => {
        service.selectedDate = new Date();
        const parsedTime = service.parsePartiallyEnteredTime('1:mm');
        expect(parsedTime.getMinutes()).toBe(0);
        expect(parsedTime.getHours()).toBe(1);
    });
    it('should set the hours to 0 when time entered only has valid mins', () => {
        service.selectedDate = new Date();
        const parsedTime = service.parsePartiallyEnteredTime('HH:02');
        expect(parsedTime.getHours()).toBe(0);
        expect(parsedTime.getMinutes()).toBe(2);
    });
    it('should return null when time entered is null or undefined', () => {
        let parsedTime = service.parsePartiallyEnteredTime(undefined);
        expect(parsedTime).toBeNull();
        parsedTime = service.parsePartiallyEnteredTime(null);
        expect(parsedTime).toBeNull();
    });
});
describe('time calculation parses partial time', () => {
    beforeEach(() => {
        timeSettings.displaySeconds = true;
        service.selectedDate = new Date();
    });
    it('sets the seconds to zero when not specified', () => {
        const parsedTime = service.parsePartiallyEnteredTime('12:mm:ss');
        expect(parsedTime.getMinutes()).toBe(0);
        expect(parsedTime.getHours()).toBe(12);
        expect(parsedTime.getSeconds()).toBe(0);
    });
    it('sets the seconds where specified', () => {
        const parsedTime = service.parsePartiallyEnteredTime('12:mm:10');
        expect(parsedTime.getMinutes()).toBe(0);
        expect(parsedTime.getHours()).toBe(12);
        expect(parsedTime.getSeconds()).toBe(10);
    });
    it('sets the seconds where specified and in 12-hour format', () => {
        timeSettings.is12HourFormat = true;
        const parsedTime = service.parsePartiallyEnteredTime('10:mm:01 AM');
        expect(parsedTime.getMinutes()).toBe(0);
        expect(parsedTime.getHours()).toBe(10);
        expect(parsedTime.getSeconds()).toBe(1);
    });
    it('sets the correct time where lowercase designator is specified and in 12-hour format', () => {
        timeSettings.is12HourFormat = true;
        const parsedTime = service.parsePartiallyEnteredTime('01:30:10 pm');
        expect(parsedTime.getMinutes()).toBe(30);
        expect(parsedTime.getHours()).toBe(13);
    });
});

describe('time calculation parses partial time duration', () => {
    beforeEach(() => {
        timeSettings.displaySeconds = true;
        service.selectedDate = new Date();
    });
    it('sets the seconds to zero when not specified', () => {
        const parsedTime = service.parsePartiallyEnteredDuration('12:mm:ss');
        expect(parsedTime.getMinutes()).toBe(0);
        expect(parsedTime.getHours()).toBe(12);
        expect(parsedTime.getSeconds()).toBe(0);
    });
    it('sets the seconds where specified', () => {
        const parsedTime = service.parsePartiallyEnteredDuration('12:mm:10');
        expect(parsedTime.getMinutes()).toBe(0);
        expect(parsedTime.getHours()).toBe(12);
        expect(parsedTime.getSeconds()).toBe(10);
    });
});
describe('parsing elapsed time when showing seconds', () => {
    beforeEach(() => {
        service.selectedDate = new Date(2000, 1, 1);
        timeSettings.displaySeconds = true;
    });
    it('sets the correct duration when in 12-hour format', () => {
        timeSettings.is12HourFormat = true;
        let duration = service.parseElapsedTime('HH:05:10');
        expect(duration.getHours()).toBe(0);
        expect(duration.getMinutes()).toBe(5);
        expect(duration.getSeconds()).toBe(10);
        duration = service.parseElapsedTime('12:05:10');
        expect(duration.getHours()).toBe(12);
        expect(duration.getMinutes()).toBe(5);
        expect(duration.getSeconds()).toBe(10);
        duration = service.parseElapsedTime('12:mm:10');
        expect(duration.getHours()).toBe(12);
        expect(duration.getMinutes()).toBe(0);
        expect(duration.getSeconds()).toBe(10);
    });
    it('sets the correct duration when in 24-hour format', () => {
        timeSettings.is12HourFormat = false;
        let duration = service.parseElapsedTime('HH:05:10');
        expect(duration.getHours()).toBe(0);
        expect(duration.getMinutes()).toBe(5);
        expect(duration.getSeconds()).toBe(10);
        duration = service.parseElapsedTime('13:05:10');
        expect(duration.getHours()).toBe(13);
        expect(duration.getMinutes()).toBe(5);
        expect(duration.getSeconds()).toBe(10);
        duration = service.parseElapsedTime('13:mm:10');
        expect(duration.getHours()).toBe(13);
        expect(duration.getMinutes()).toBe(0);
        expect(duration.getSeconds()).toBe(10);
    });
});
describe('parsing elapsed time when not showing seconds', () => {
    beforeEach(() => {
        service.selectedDate = new Date(2000, 1, 1);
        timeSettings.displaySeconds = false;
    });
    describe('and showing 12-hour format', () => {
        beforeEach(() => {
            timeSettings.is12HourFormat = true;
        });
        it('sets the correct duration', () => {
            const duration = service.parseElapsedTime('12:05');
            expect(duration.getHours()).toBe(12);
            expect(duration.getMinutes()).toBe(5);
            expect(duration.getSeconds()).toBe(0);
        });
        it('sets the correct duration when no hours specified', () => {
            const duration = service.parseElapsedTime('HH:05');
            expect(duration.getHours()).toBe(0);
            expect(duration.getMinutes()).toBe(5);
            expect(duration.getSeconds()).toBe(0);
        });
        it('sets the correct duration when no minutes specified', () => {
            const duration = service.parseElapsedTime('12:mm');
            expect(duration.getHours()).toBe(12);
            expect(duration.getMinutes()).toBe(0);
            expect(duration.getSeconds()).toBe(0);
        });
    });
    describe('and showing 24-hour format', () => {
        beforeEach(() => {
            timeSettings.is12HourFormat = false;
        });
        it('sets the correct duration', () => {
            const duration = service.parseElapsedTime('13:05');
            expect(duration.getHours()).toBe(13);
            expect(duration.getMinutes()).toBe(5);
            expect(duration.getSeconds()).toBe(0);
        });
        it('sets the correct duration when no hours specified', () => {
            const duration = service.parseElapsedTime('HH:05');
            expect(duration.getHours()).toBe(0);
            expect(duration.getMinutes()).toBe(5);
            expect(duration.getSeconds()).toBe(0);
        });
        it('sets the correct duration when no minutes specified', () => {
            const duration = service.parseElapsedTime('13:mm');
            expect(duration.getHours()).toBe(13);
            expect(duration.getMinutes()).toBe(0);
            expect(duration.getSeconds()).toBe(0);
        });
    });
});
describe('Time Calculation - Initialize Start time ', () => {
    it('should return null if the setting for timeEmptyForNewEntries is on', () => {
        const init = service.initializeStartTime(true, null);
        expect(init).toBeNull();
    });
    it('should initialize start time to today if siteCtrl\'s timeEmptyForNewEntries is false and timeservice data is empty', () => {
        timeService.timeList = null;
        const selectedDate = new Date();
        service.selectedDate = selectedDate;
        const startTime = service.initializeStartTime(false, false);
        expect(startTime.getFullYear()).toBe(selectedDate.getFullYear());
        expect(startTime.getMonth()).toBe(selectedDate.getMonth());
        expect(startTime.getDate()).toBe(selectedDate.getDate());
    });
    it('should initialize start time with zero seconds if timeservice data is empty and timeSettings.displaySeconds is off', () => {
        timeSettings.displaySeconds = false;
        timeService.timeList = null;
        const selectedDate = new Date();
        service.selectedDate = selectedDate;
        const startTime = service.initializeStartTime(false, false);
        expect(startTime.getFullYear()).toBe(selectedDate.getFullYear());
        expect(startTime.getMonth()).toBe(selectedDate.getMonth());
        expect(startTime.getDate()).toBe(selectedDate.getDate());
        expect(startTime.getSeconds()).toBe(0);
    });
    it('should call _getDateWithCurrentTime for continuedTime', () => {
        service._getDateWithCurrentTime = jest.fn();
        service.selectedDate = new Date();
        timeSettings.continueFromCurrentTime = true;
        service.initializeStartTime(false, true);
        expect(service._getDateWithCurrentTime).toHaveBeenCalledWith(service.selectedDate);
    });
    it('should return the latest finish of the entries', () => {
        timeService.timeList = [{
            start: '2020-01-09T11:48:00',
            finish: '2020-01-09T11:48:00'
        }, {
            start: '2020-01-09T10:48:00',
            finish: '2020-01-09T12:48:00'
        }, {
            start: '2020-01-09T09:48:00',
            finish: '2020-01-09T13:48:00'
        }] as unknown as Array<TimeEntryEx>;
        service.calculateElapsedMinMax = jest.fn();
        timeSettings.displaySeconds = true;
        const init = service.initializeStartTime(false, false);
        expect(init.toISOString()).toBe((new Date(timeService.timeList[2].finish)).toISOString());
    });
    it('should initialize start time to selected date if siteCtrl\'s timeEmptyForNewEntries is false and timeservice data is empty', () => {
        service.calculateElapsedMinMax = jest.fn();
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        timeService.timeList = null;

        service.selectedDate = tomorrow;
        let startTime = service.initializeStartTime(false, false);
        expect(startTime.getDate()).toBe(tomorrow.getDate());
        expect(startTime.getMonth()).toBe(tomorrow.getMonth());
        expect(startTime.getFullYear()).toBe(tomorrow.getFullYear());

        service.selectedDate = yesterday;
        startTime = service.initializeStartTime(false, false);
        expect(startTime.getDate()).toBe(yesterday.getDate());
        expect(startTime.getMonth()).toBe(yesterday.getMonth());
        expect(startTime.getFullYear()).toBe(yesterday.getFullYear());
    });
    it('should initialize start time to the latest finish of the entries if siteCtrl\'s timeEmptyForNewEntries is false', () => {
        service.selectedDate = new Date();
        timeService.timeList = [
            {
                caseKey: -457,
                start: '2019-07-11T09:19:00',
                finish: '2019-07-11T10:19:00',
                elapsedTimeInSeconds: 3600
            },
            {
                caseKey: -457,
                start: '2019-07-11T09:19:00',
                finish: '2019-07-11T10:20:00',
                elapsedTimeInSeconds: 3600
            }
        ] as unknown as Array<TimeEntryEx>;

        const startTime = service.initializeStartTime(false, false);
        expect(startTime.toTimeString()).toBe(new Date(timeService.timeList[1].finish).toTimeString());
    });
    it('should reset the start time seconds to zero if timeSettings.displaySeconds is false', () => {
        timeSettings.displaySeconds = false;
        service.selectedDate = new Date();
        timeService.timeList = [
            {
                caseKey: -457,
                start: '2019-07-11T09:19:00',
                finish: '2019-07-11T10:19:20',
                elapsedTimeInSeconds: 3600
            },
            {
                caseKey: -457,
                start: '2019-07-11T09:19:00',
                finish: '2019-07-11T10:20:10',
                elapsedTimeInSeconds: 3600
            }
        ] as unknown as Array<TimeEntryEx>;

        const startTime = service.initializeStartTime(false, false);
        expect(startTime.getTime()).toBe(new Date(timeService.timeList[1].finish).setSeconds(0));
        expect(startTime.getSeconds()).toBe(0);
    });
});

describe('Time Calculation - Get date with current time', () => {
    it('should return current time for any selected date', () => {
        const currHours = (new Date()).getHours();
        const currMins = (new Date()).getMinutes();
        const currSeconds = (new Date()).getSeconds();
        const selectedDate = new Date(2020, 0, 1);
        service.calculateElapsedMinMax = jest.fn();
        const currTime = service._getDateWithCurrentTime(selectedDate);
        expect(currTime.getDate()).toBe(selectedDate.getDate());
        expect(currTime.getHours()).toBe(currHours);
        expect(currTime.getMinutes()).toBe(currMins);
        expect(currTime.getSeconds()).toBe(currSeconds);
    });
    it('should return current time with zero seconds if ', () => {
        timeSettings.displaySeconds = false;
        const currHours = (new Date()).getHours();
        const currMins = (new Date()).getMinutes();
        const selectedDate = new Date(2020, 0, 1);
        service.calculateElapsedMinMax = jest.fn();
        const currTime = service._getDateWithCurrentTime(selectedDate);
        expect(currTime.getDate()).toBe(selectedDate.getDate());
        expect(currTime.getHours()).toBe(currHours);
        expect(currTime.getMinutes()).toBe(currMins);
        expect(currTime.getSeconds()).toBe(0);
    });
});

describe('Duration Calculation from units', () => {
    beforeEach(() => {
        timeSettings.unitsPerHour = 10;
    });
    it('should return duration ', () => {
        const duration = service.calcDurationFromUnits(15);
        expect(duration instanceof Date).toBe(true);
        expect(duration.getHours()).toBe(1);
    });
    it('should calculate correct duration with time carried over', () => {
        const duration = service.calcDurationFromUnits(21, 3600); // 21 units entered, 1 hour carried over
        expect(duration instanceof Date).toBe(true);
        expect(duration.getHours()).toBe(1);
        expect(duration.getMinutes()).toBe(6);
    });
});

describe('Units Calculation from duration', () => {
    beforeEach(() => {
        timeSettings.unitsPerHour = 10;
    });
    it('should return units correctly based on the roundUp units site control', () => {
        timeSettings.roundUpUnits = false;
        timeSettings.considerSecsInUnitsCalc = false;
        const date = new Date(1899, 0, 1, 10, 20, 10);
        let units = service.calcUnitsFromDuration(date);
        expect(units).toBe(103);

        timeSettings.roundUpUnits = true;
        units = service.calcUnitsFromDuration(date);
        expect(units).toBe(104);
    });
    it('should consider seconds in units calc when site control is on', () => {
        timeSettings.roundUpUnits = false;
        timeSettings.considerSecsInUnitsCalc = true;
        const date = new Date(1899, 0, 1, 10, 20, 10);
        let units = service.calcUnitsFromDuration(date);
        expect(units).toBe(203);

        timeSettings.roundUpUnits = true;
        units = service.calcUnitsFromDuration(date);
        expect(units).toBe(204);
    });
    it('should add accumulated time in units calc', () => {
        timeSettings.roundUpUnits = false;
        timeSettings.considerSecsInUnitsCalc = true;
        const date = new Date(1899, 0, 1, 10, 20, 10);
        let units = service.calcUnitsFromDuration(date, 300);
        expect(units).toBe(204);

        timeSettings.roundUpUnits = true;
        units = service.calcUnitsFromDuration(date, 300);
        expect(units).toBe(205);
    });

    it('should consider only 2 decimal points while working with fractions', () => {
        timeSettings.roundUpUnits = true;
        timeSettings.considerSecsInUnitsCalc = false;
        timeSettings.unitsPerHour = 60;

        const date = new Date(1899, 0, 1, 0, 31, 10);
        const units = service.calcUnitsFromDuration(date, 0);
        expect(units).toBe(31);
    });
});

describe('Calculating duration from start and finish', () => {
    beforeEach(() => {
        service.selectedDate = new Date(2000, 0, 1);
    });
    it('should return null if no start and finish supplied', () => {
        expect(service.calculateElapsed(null, null)).toBeNull();
    });
    it('should return null if finish is before start', () => {
        const start = new Date(Date.UTC(2000, 0, 1, 9, 0, 5));
        const finish = new Date(Date.UTC(2000, 0, 1, 9, 0, 1));
        expect(service.calculateElapsed(start, finish)).toBeNull();
    });
    it('should return the elapsed time', () => {
        const start = new Date(Date.UTC(2000, 0, 1, 9, 10, 5));
        const finish = new Date(Date.UTC(2000, 0, 1, 10, 11, 6));
        const result = service.calculateElapsed(start, finish);
        expect(result.getFullYear()).toBe(1899);
        expect(result.getMonth()).toBe(0);
        expect(result.getDate()).toBe(1);
        expect(result.getHours()).toBe(1);
        expect(result.getMinutes()).toBe(1);
        expect(result.getSeconds()).toBe(1);
    });
});

describe('Calculating finish from start and duration', () => {
    beforeEach(() => {
        service.selectedDate = new Date(2000, 0, 1);
    });
    it('calculates the finish time by adding start and duration time component', () => {
        const result = service.calculateFinished(new Date(2000, 0, 1, 8, 1, 1), new Date(1899, 0, 2, 1, 1, 1));
        expect(result.getFullYear()).toBe(2000);
        expect(result.getMonth()).toBe(0);
        expect(result.getDate()).toBe(1);
        expect(result.getHours()).toBe(9);
        expect(result.getMinutes()).toBe(2);
        expect(result.getSeconds()).toBe(2);
    });
});

describe('Calculating start from finish and duration', () => {
    beforeEach(() => {
        service.selectedDate = new Date(2000, 0, 1);
    });
    it('returns null if duration forces start to be previous date', () => {
        expect(service.calculateStart(new Date(2000, 0, 1, 8, 2, 2), new Date(1899, 0, 2, 9, 1, 1))).toBeNull();
        expect(service.calculateStart(new Date(2000, 0, 1, 8, 2, 2), new Date(1899, 0, 2, 8, 3, 1))).toBeNull();
        expect(service.calculateStart(new Date(2000, 0, 1, 8, 2, 2), new Date(1899, 0, 2, 8, 2, 3))).toBeNull();
    });
    it('calculated the start time by subtracting duration from finish time', () => {
        const result = service.calculateStart(new Date(2000, 0, 1, 8, 2, 2), new Date(1899, 0, 2, 1, 1, 1));
        expect(result.getFullYear()).toBe(2000);
        expect(result.getMonth()).toBe(0);
        expect(result.getDate()).toBe(1);
        expect(result.getHours()).toBe(7);
        expect(result.getMinutes()).toBe(1);
        expect(result.getSeconds()).toBe(1);
    });
});

describe('Get start time', () => {
    it('should return the correct time components for the specified datetime', () => {
        const selectedDate = new Date();
        const result = service.getStartTime(selectedDate);
        expect(result.getHours()).toBe(selectedDate.getHours());
        expect(result.getMinutes()).toBe(selectedDate.getMinutes());
        expect(result.getSeconds()).toBe(selectedDate.getSeconds());
    });
    it('should set the seconds to zero if displaySeconds is off', () => {
        timeSettings.displaySeconds = false;
        const selectedDate = new Date();
        const result = service.getStartTime(selectedDate);
        expect(result.getHours()).toBe(selectedDate.getHours());
        expect(result.getMinutes()).toBe(selectedDate.getMinutes());
        expect(result.getSeconds()).toBe(0);
    });
    it('should set the seconds for timers regardless of displaySeconds preference', () => {
        timeSettings.displaySeconds = false;
        const selectedDate = new Date();
        const result = service.getStartTime(selectedDate, true);
        expect(result.getHours()).toBe(selectedDate.getHours());
        expect(result.getMinutes()).toBe(selectedDate.getMinutes());
        expect(result.getSeconds()).toBe(selectedDate.getSeconds());
    });
});