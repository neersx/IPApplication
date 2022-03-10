import { Injectable } from '@angular/core';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';
import { TimeSettingsService } from './settings/time-settings.service';
import { TimeRecordingService } from './time-recording-service';

@Injectable()
export class TimeCalculationService {
    min: Date = null;
    max: Date = new Date(1899, 0, 1, 23, 59, 59);
    selectedDate: Date = null;
    constructor(private readonly timeService: TimeRecordingService, private readonly settingsService: TimeSettingsService) { }

    calculateElapsed(start: Date, finish: Date): Date {
        if (!!start && !!finish) {
            const totalFinishedSecs = (finish.getHours() * 3600) + (finish.getMinutes() * 60) + finish.getSeconds();
            const totalStartSecs = (start.getHours() * 3600) + (start.getMinutes() * 60) + start.getSeconds();
            const totalElapsedSecs = totalFinishedSecs - totalStartSecs;
            if (totalElapsedSecs < 0) {
                return null;
            }
            const elapsed = DateFunctions.convertSecondsToTime(Math.abs(totalElapsedSecs));

            return new Date(1899, 0, 1, elapsed.hours, elapsed.mins, elapsed.secs);
        }

        return null;
    }

    calculateFinished(start: Date, elapsed: Date): Date {
        const year = this.selectedDate.getFullYear();
        const month = this.selectedDate.getMonth();
        const date = this.selectedDate.getDate();
        const totalStartSecs = (start.getHours() * 3600) + (start.getMinutes() * 60) + start.getSeconds();
        const totalElapsedSecs = (elapsed.getHours() * 3600) + (elapsed.getMinutes() * 60) + elapsed.getSeconds();
        const finish = DateFunctions.convertSecondsToTime(totalStartSecs + totalElapsedSecs);

        return new Date(year, month, date, finish.hours, finish.mins, finish.secs);
    }

    calculateStart(finish: Date, elapsed: Date): Date {
        const year = this.selectedDate.getFullYear();
        const month = this.selectedDate.getMonth();
        const date = this.selectedDate.getDate();
        const totalFinishSecs = (finish.getHours() * 3600) + (finish.getMinutes() * 60) + finish.getSeconds();
        const totalElapsedSecs = (elapsed.getHours() * 3600) + (elapsed.getMinutes() * 60) + elapsed.getSeconds();
        const startSecs = totalFinishSecs - totalElapsedSecs;
        if (startSecs < 0) {
            return null;
        }
        const start = DateFunctions.convertSecondsToTime(totalFinishSecs - totalElapsedSecs);

        return new Date(year, month, date, start.hours, start.mins, start.secs);
    }

    calculateElapsedMinMax(start: Date): void {
        if (start) {
            const startDate = start.getDate();
            const startHours = start.getHours();
            const startMins = start.getMinutes();
            const maxHours = 23 - startHours;
            const maxMins = 59 - startMins;
            this.max = new Date(1899, 0, 1, maxHours, maxMins);
            this.min = new Date(start.getFullYear(), start.getMonth(), this.selectedDate.getDate(), startHours, startMins);
        }
    }

    calculateElapsedMinMaxWithFinishedTime(finish: Date): void {
        if (finish) {
            this.max = new Date(1899, 0, 1, 23 - finish.getHours(), 59 - finish.getMinutes()); // setting max to be the finished time itself
        }
    }

    clearMinMax(): void {
        this.min = new Date(this.selectedDate.getFullYear(), this.selectedDate.getMonth(), this.selectedDate.getMonth(), 0, 0, 0);
        this.max = new Date(1899, 0, 1, 23, 59, 59);
    }

    // kendo Timepicker doesnt keep track of the date even if min/max values are assinged. Hence we need to explicitly lock the year, month, date to whatever date it is navigated to.
    lockYearMonthDate(date: Date): Date {
        if (date) {
            date.setFullYear(this.selectedDate.getFullYear());
            date.setMonth(this.selectedDate.getMonth());
            date.setDate(this.selectedDate.getDate());
        }

        return date;
    }

    parsePartiallyEnteredDuration(dateInput: any): Date {
        if (dateInput) {
            if (dateInput instanceof Date) {
                return dateInput;
            }

            if ((dateInput.toLowerCase().includes('hh:mm') && !this.settingsService.displaySeconds) || (dateInput.toLowerCase().includes('hh:mm:ss') && this.settingsService.displaySeconds)) {
                return null;
            }

            const input = dateInput.toLowerCase();
            const replaced = input.replace(this.settingsService.is12HourFormat ? /[hms]/g : /[hms]/gi, '0');
            // tslint:disable-next-line: no-parameter-reassignment
            dateInput = replaced;

            const hoursDigit = Number(replaced.split(':')[0]);
            const mins = Number((replaced.split(':'))[1].substr(0, 2));
            const seconds = this.settingsService.displaySeconds && !!replaced.split(':')[2] ? Number((replaced.split(':')[2]).substr(0, 2)) : 0;

            if (hoursDigit > 0 || mins > 0 || seconds > 0) {
                const result = new Date(1899, 0, 1, hoursDigit, mins, seconds);

                return result;
            }
        }

        return null;
    }

    parsePartiallyEnteredTime(dateInput: any): Date {
        if (dateInput) {
            if (dateInput instanceof Date) {
                return this.lockYearMonthDate(dateInput);
            }

            if ((dateInput.toLowerCase().includes('hh:mm') && !this.settingsService.displaySeconds) || (dateInput.toLowerCase().includes('hh:mm:ss') && this.settingsService.displaySeconds)) {
                return null;
            }
            const input = dateInput.toLowerCase();
            const isPm = dateInput.toUpperCase().indexOf('PM') > 0;
            const replaced = input.replace(this.settingsService.is12HourFormat ? /[hms]/g : /[hms]/gi, '0');
            // tslint:disable-next-line: no-parameter-reassignment
            dateInput = replaced;

            const hoursDigit = Number(replaced.split(':')[0]);
            const hours = this.settingsService.is12HourFormat ? hoursDigit + (hoursDigit < 12 && isPm ? 12 : 0) : hoursDigit;
            const mins = Number((replaced.split(':'))[1].substr(0, 2));
            const seconds = this.settingsService.displaySeconds && !!replaced.split(':')[2] ? Number((replaced.split(':')[2]).substr(0, 2)) : 0;

            if (hours > 0 || mins > 0 || seconds > 0) {
                const result = new Date(1899, 0, 1, hours, mins, seconds);

                return this.lockYearMonthDate(result);
            }
        }

        return null;
    }

    parseElapsedTime(dateInput: string): Date {
        if (dateInput) {
            if ((dateInput.includes('HH:mm') && !this.settingsService.displaySeconds) || (dateInput.includes('HH:mm:ss') && this.settingsService.displaySeconds)) {

                return null;
            }
            const input = dateInput;
            const replaced = input.replace(/[hms]/gi, '0');
            // tslint:disable-next-line: no-parameter-reassignment
            dateInput = replaced;

            const hoursDigit = Number(replaced.split(':')[0]);
            const hours = hoursDigit;
            const mins = Number((replaced.split(':'))[1].substr(0, 2));
            const seconds = this.settingsService.displaySeconds && !!replaced.split(':')[2] ? Number((replaced.split(':')[2]).substr(0, 2)) : 0;

            return new Date(this.selectedDate.getFullYear(), this.selectedDate.getMonth(), this.selectedDate.getDate(), hours, mins, seconds);
        }

        return null;
    }

    initializeStartTime(timeEmptyForNewEntries: boolean, isContinued: boolean): Date | null {
        let startTime: Date = null;
        if (isContinued && this.settingsService.continueFromCurrentTime) {
            return this._getDateWithCurrentTime(this.selectedDate);
        }
        if (timeEmptyForNewEntries) {
            return null;
        }
        if (this.timeService.timeList && this.timeService.timeList.length) {
            let finishDates = null;
            const entriesWithFinished = _.filter(this.timeService.timeList, (entry: any) => { return entry.finish; });
            if (entriesWithFinished.length) {
                finishDates = _.pluck(entriesWithFinished, 'finish').map(date => new Date(date));
                startTime = new Date(Math.max.apply(null, finishDates));
                if (!this.settingsService.displaySeconds) {
                    startTime.setSeconds(0);
                }
            } else {
                startTime = this.getStartTime(this.selectedDate);
            }

            this.calculateElapsedMinMax(startTime);

            return startTime;
        }

        return this._getDateWithCurrentTime(this.selectedDate);
    }

    private _getDateWithCurrentTime(currentDate: Date): Date {
        const startTime = this.getStartTime(currentDate);
        this.calculateElapsedMinMax(startTime);

        return startTime;
    }

    getStartTime(currentDate: Date, forTimer?: boolean): Date {
        const startDate = new Date(currentDate);
        const timeOfDay = new Date();
        startDate.setHours(timeOfDay.getHours());
        startDate.setMinutes(timeOfDay.getMinutes());
        if (!!this.settingsService.displaySeconds || forTimer) {
            startDate.setSeconds(timeOfDay.getSeconds());
        } else {
            startDate.setSeconds(0);
        }

        return startDate;
    }

    getElapsedSeconds(start: Date, finish: Date): number {

        return (finish.getTime() - start.getTime()) / 1000;
    }

    toLocalDate(dateTime: Date, dateOnly?: boolean): Date {

        return new Date(Date.UTC(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate(), dateOnly ? 0 : dateTime.getHours(), dateOnly ? 0 : dateTime.getMinutes(), dateOnly ? 0 : dateTime.getSeconds()));
    }

    calcDurationFromUnits = (totalUnits: number, secondsCarriedForward = 0): Date => {
        const unitsCarriedForward = (secondsCarriedForward / 3600) * this.settingsService.unitsPerHour;
        const hours = Math.round((totalUnits - unitsCarriedForward) / this.settingsService.unitsPerHour);
        const minutes = ((totalUnits - unitsCarriedForward) * 60 / this.settingsService.unitsPerHour) - (hours * 60);

        return new Date(1899, 0, 1, hours, minutes);
    };

    calcUnitsFromDuration = (date: Date, secondsCarriedForward = 0): number => {
        if (date) {
            let units;

            // tslint:disable-next-line: prefer-conditional-expression
            if (this.settingsService.considerSecsInUnitsCalc) {
                units = (date.getHours() + (date.getMinutes() / 60) + (date.getSeconds() + secondsCarriedForward / 3600)) * this.settingsService.unitsPerHour;
            } else {
                units = (date.getHours() + date.getMinutes() / 60 + secondsCarriedForward / 3600) * this.settingsService.unitsPerHour;
            }

            units = +units.toFixed(2);
            if (this.settingsService.roundUpUnits) {
                return (Math.ceil(units));
            }

            return (Math.round(units));
        }

        return null;
    };

    getCurrentTimeFor = (d: Date): Date => {
        const current = new Date();
        d.setHours(current.getHours());
        d.setMinutes(current.getMinutes());
        if (!!this.settingsService.displaySeconds) {
            d.setSeconds(current.getSeconds());
        } else {
            d.setSeconds(0);
        }

        return d;
    };
}