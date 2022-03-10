import { DateFunctions } from './date-functions';

describe('Date functions', () => {
    it('convertsTimeToSeconds if date provided', () => {
        const result = DateFunctions.convertTimeToSeconds(new Date(2020, 11, 1, 10, 10, 11));
        expect(result).toBe(10 * 3600 + 10 * 60 + 11);
    });

    it('convertsTimeToSeconds returns zero if date is not passed', () => {
        const result = DateFunctions.convertTimeToSeconds(null);
        expect(result).toEqual(0);
    });

    it('setTimeOnDate sets time on given date', () => {
        const result = DateFunctions.setTimeOnDate(new Date(2020, 10, 11), 1, 2, 3);
        expect(result).toEqual(new Date(2020, 10, 11, 1, 2, 3, 0));
    });

    it('setTimeOnDate sreturns null if date not provided', () => {
        const result = DateFunctions.setTimeOnDate(null, 1, 2, 3);
        expect(result).toBeNull();
    });
});