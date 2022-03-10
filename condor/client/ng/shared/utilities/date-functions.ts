export class DateFunctions {
    static toLocalDate(dateTime: Date, dateOnly?: boolean): Date {
        if (dateTime instanceof Date) {
            return new Date(Date.UTC(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate(), dateOnly ? 0 : dateTime.getHours(), dateOnly ? 0 : dateTime.getMinutes(), dateOnly ? 0 : dateTime.getSeconds()));
        }

        return null;
    }

    static getSeconds(dateTime: Date): number {
        if (!!dateTime) {
            return dateTime.getHours() * 3600 + dateTime.getMinutes() * 60 + dateTime.getSeconds();
        }

        return null;
    }

    static getDateOnly(dateTime: Date): Date {
        if (!!dateTime) {
            dateTime.setHours(0);
            dateTime.setMinutes(0);
            dateTime.setSeconds(0);
            dateTime.setMilliseconds(0);

            return dateTime;
        }

        return null;
    }

    static setTimeOnDate(dateTime: Date, hours: number, minutes: number, seconds: number): Date {
        if (!!dateTime) {
            dateTime.setHours(hours);
            dateTime.setMinutes(minutes);
            dateTime.setSeconds(seconds);
            dateTime.setMilliseconds(0);

            return dateTime;
        }

        return null;
    }

    static convertSecondsToTime(value: number): Time {
        const h = Math.floor(value / 3600);
        const m = Math.floor(value % 3600 / 60);
        const s = Math.floor(value % 3600 % 60);

        return { hours: h, mins: m, secs: s };
    }

    static convertTimeToSeconds(date: Date): number {
        if (!!date) {
            return date.getHours() * 3600 + date.getMinutes() * 60 + date.getSeconds();
        }

        return 0;
    }
}

export interface Time {
    hours: number;
    mins: number;
    secs?: number;
}
