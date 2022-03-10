import { DatePipe } from '@angular/common';
import { Pipe, PipeTransform } from '@angular/core';
import { DateService } from 'ajs-upgraded-providers/date-service.provider';

@Pipe({
    name: 'localeDate'
})

export class LocaleDatePipe implements PipeTransform {

    constructor(private readonly dateService: DateService) { }

    transform(dateValue: any, args: any): any {
        let dateFormat = this.dateService.dateFormat;
        dateFormat = (dateFormat.toUpperCase() !== 'SHORTDATE' ? dateFormat : this.dateService.shortDateFormat);

        if (args) {
            dateFormat = `${dateFormat} ${args}`;
        }

        return new DatePipe('en').transform(dateValue, dateFormat);
    }
}
