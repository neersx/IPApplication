import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

@Component({
    selector: 'ipx-event-other-details',
    templateUrl: './event-other-details.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class EventOtherDetailsComponent {
    @Input() event: any;

    encodeLinkData = (data) => {
        return encodeURIComponent(JSON.stringify(data));
    };
}