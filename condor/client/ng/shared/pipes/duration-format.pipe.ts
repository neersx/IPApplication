import { DatePipe } from '@angular/common';
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'durationFormat' })
export class DurationFormatPipe implements PipeTransform {
    constructor(public datePipe: DatePipe) {}
    transform(secs: number, displaySeconds?: boolean): any {
        if (secs == null || secs === undefined) {
            return '';
        }
        if (secs > 86399) {
            const hours = Math.floor(secs / 3600);
            const mins = secs % 3600;
            const minutes = Math.floor(mins / 60);
            const seconds = mins % 60;

            return this.formatDuration(hours, minutes, seconds, displaySeconds);
        }
        const format = !!displaySeconds ? 'HH:mm:ss' : 'HH:mm';

        return this.datePipe.transform(
            new Date(0, 0, 0).setSeconds(secs),
            format
        );
    }

    private readonly formatDuration = (hours: number, minutes: number, seconds: number, displaySeconds?: boolean): string => {
        const hoursString = hours < 10 ? '0' + hours.toString.toString() : hours.toString();
        const minString = minutes < 10 ? '0' + minutes.toString() : minutes.toString();
        const secondString = !!displaySeconds ? ':' + (seconds < 10 ? '0' + seconds.toString() : seconds.toString()) : '';

        return `${hoursString}:${minString}${secondString}`;
    };
}
