export class DateHelperMock {
    convertForDatePicker = jest.fn();
    areDatesEqual = jest.fn();
    toLocal = (val) => val;
}