import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import * as _ from 'underscore';
import { RemindersInfo } from './event-rule-details.model';

@Component({
    selector: 'ipx-event-reminders',
    templateUrl: './event-reminders.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class EventRemindersComponent {
    @Input() remindersInfo: Array<RemindersInfo>;

    byItem = (index: number, item: any): string => item;
}