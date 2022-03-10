export class DateHelperMock {
    toLocal = (selectedDate: Date) => selectedDate.toISOString().split('T')[0];
    addMonths = (selectedDate: Date, month?: number) => selectedDate;
}
