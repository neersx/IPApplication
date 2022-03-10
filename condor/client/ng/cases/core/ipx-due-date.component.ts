import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import * as moment from 'moment';

@Component({
    selector: 'ipx-due-date',
    templateUrl: 'ipx-due-date.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxDueDateComponent {
    _date: string;
    isOverdue: boolean;
    isToday: boolean;

    @Input() set date(value: string) {
        this.isToday = moment().isSame(moment(value), 'day');
        this.isOverdue = moment().isSameOrAfter(moment(value), 'day');
        this._date = value;
    }

    get date(): string {
        return this._date;
    }

    @Input() showToolTip: boolean;
}