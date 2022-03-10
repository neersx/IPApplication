import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
    name: 'removeTimezone'
})

export class RemoveTimezonePipe implements PipeTransform {
    transform(value: Date): any {
        let v = value;
        if (!(v instanceof Date)) {
            v = new Date(v);
        }

        return new Date(v.getUTCFullYear(), v.getUTCMonth(), v.getUTCDate(), v.getUTCHours(), v.getUTCMinutes(), v.getSeconds(), v.getUTCMilliseconds());
    }
}