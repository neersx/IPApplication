export class TimeRecordingHelper {
    static initiateTimeEntry = (caseKey: number): void => {
        const linkElement = document.createElement('a');
        linkElement.href = `#/accounting/time/${caseKey}`;
        linkElement.target = '_blank';
        linkElement.click();
    };

    static currentWeek = (today: Date): Array<Date> => {
        const fromDate = new Date(today);
        const toDate = new Date(today);
        const week = [];
        const firstDay = new Date(fromDate.setDate(today.getDate() - today.getDay() + 1));
        const lastDay = new Date(toDate.setDate(today.getDate() - today.getDay() + 7));
        week.push(firstDay);
        week.push(lastDay);

        return week;
    };

    static lastWeek = (today: Date): Array<Date> => {
        const fromDate = new Date(today);
        const toDate = new Date(today);
        const offset = today.getDate() - today.getDay() - 6;
        const week = [];
        const firstDay = new Date(fromDate.setDate(offset));
        const lastDay = new Date(toDate.setDate(offset + 6));
        week.push(firstDay);
        week.push(lastDay);

        return week;
    };

    static currentMonth = (): Array<Date> => {
        const thisMonth = new Date();
        const month = [];
        const firstDayOfMonth = new Date(thisMonth.getFullYear(), thisMonth.getMonth(), 1);
        const lastDayOfMonth = new Date(thisMonth.getFullYear(), thisMonth.getMonth(), TimeRecordingHelper.daysInMonth(thisMonth.getFullYear(), thisMonth.getMonth() + 1));
        month.push(firstDayOfMonth);
        month.push(lastDayOfMonth);

        return month;
    };

    static lastMonth = (): Array<Date> => {
        const lastMonth = new Date();
        lastMonth.setMonth(lastMonth.getMonth() - 1);
        const month = [];
        const firstDayOfMonth = new Date(lastMonth.getFullYear(), lastMonth.getMonth(), 1);
        const lastDayOfMonth = new Date(lastMonth.getFullYear(), lastMonth.getMonth(), TimeRecordingHelper.daysInMonth(lastMonth.getFullYear(), lastMonth.getMonth() + 1));
        month.push(firstDayOfMonth);
        month.push(lastDayOfMonth);

        return month;
    };

    static daysInMonth = (year, month): number => {
        return new Date(year, month, 0).getDate();
    };
}