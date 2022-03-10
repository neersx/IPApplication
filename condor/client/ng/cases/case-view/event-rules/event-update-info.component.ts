import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { EventUpdateInfo } from './event-rule-details.model';

@Component({
    selector: 'ipx-event-update-info',
    templateUrl: './event-update-info.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class EventUpdateInfoComponent {

    @Input() eventUpdateInfo: EventUpdateInfo;

    byItem = (index: number, item: any): string => item;
}