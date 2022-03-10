import * as _ from 'underscore';
import { TimeRecordingHelper } from './time-recording-helper';

describe('TimeRecordingHelper', () => {
    it('always returns Monday as first and Sunday as last days of the current week', () => {
        let today = new Date(2021, 12, 1);
        expect(TimeRecordingHelper.currentWeek(today)[0].toDateString().includes('Mon')).toBeTruthy();
        expect(TimeRecordingHelper.currentWeek(today)[1].toDateString().includes('Sun')).toBeTruthy();
        today = new Date(2021, 11, 29);
        expect(TimeRecordingHelper.currentWeek(today)[0].toDateString().includes('Mon')).toBeTruthy();
        expect(TimeRecordingHelper.currentWeek(today)[1].toDateString().includes('Sun')).toBeTruthy();
        today = new Date(2021, 12, 4);
        expect(TimeRecordingHelper.currentWeek(today)[0].toDateString().includes('Mon')).toBeTruthy();
        expect(TimeRecordingHelper.currentWeek(today)[1].toDateString().includes('Sun')).toBeTruthy();
        today = new Date(2021, 11, 25);
        expect(TimeRecordingHelper.currentWeek(today)[0].toDateString().includes('Mon')).toBeTruthy();
        expect(TimeRecordingHelper.currentWeek(today)[1].toDateString().includes('Sun')).toBeTruthy();
    });
    it('returns first and last days of last week', () => {
        let today = new Date(2021, 12, 1);
        expect(TimeRecordingHelper.lastWeek(today)[0].toDateString().includes('Mon')).toBeTruthy();
        expect(TimeRecordingHelper.lastWeek(today)[1].toDateString().includes('Sun')).toBeTruthy();
        today = new Date(2021, 11, 29);
        expect(TimeRecordingHelper.lastWeek(today)[0].toDateString().includes('Mon')).toBeTruthy();
        expect(TimeRecordingHelper.lastWeek(today)[1].toDateString().includes('Sun')).toBeTruthy();
        today = new Date(2021, 12, 4);
        expect(TimeRecordingHelper.lastWeek(today)[0].toDateString().includes('Mon')).toBeTruthy();
        expect(TimeRecordingHelper.lastWeek(today)[1].toDateString().includes('Sun')).toBeTruthy();
        today = new Date(2021, 11, 25);
        expect(TimeRecordingHelper.lastWeek(today)[0].toDateString().includes('Mon')).toBeTruthy();
        expect(TimeRecordingHelper.lastWeek(today)[1].toDateString().includes('Sun')).toBeTruthy();
    });
    it('returns the first and last days of the current month', () => {
        const today = new Date();
        const result = TimeRecordingHelper.currentMonth();
        const firstDate = _.first(result);
        const lastDate = _.last(result);

        expect(firstDate.getDate()).toEqual(1);
        expect(firstDate.getMonth()).toEqual(today.getMonth());
        expect(lastDate.getMonth()).toEqual(today.getMonth());
    });
    it('returns the first and last days of the last month', () => {
        const lastMonth = new Date();
        lastMonth.setMonth(lastMonth.getMonth() - 1);
        const result = TimeRecordingHelper.lastMonth();
        const firstDate = _.first(result);
        const lastDate = _.last(result);

        expect(firstDate.getDate()).toEqual(1);
        expect(firstDate.getMonth()).toEqual(lastMonth.getMonth());
        expect(lastDate.getMonth()).toEqual(lastMonth.getMonth());
    });
    it('returns number of days in a month', () => {
        expect(TimeRecordingHelper.daysInMonth(2021, 1)).toEqual(31);
        expect(TimeRecordingHelper.daysInMonth(2021, 2)).toEqual(28);
        expect(TimeRecordingHelper.daysInMonth(2024, 2)).toEqual(29);
    });
});