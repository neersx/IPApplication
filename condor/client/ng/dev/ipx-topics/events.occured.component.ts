import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-Dev-Topics-EventsOccured',
    template: '<p>This is events occured subtopic.</p>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class EventsOccuredComponent implements OnInit {
    topic: Topic;

    ngOnInit(): any {
        _.extend(this.topic, {
            isEmpty: this.isEmpty,
            isActive: false
        });
    }

    isEmpty = (): boolean => {
        return false;
    };

    hasError = (): boolean => {
        return false;
    };

    getTopicCount = (): number => {
        return 7;
    };
}
