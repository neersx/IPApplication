import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-Dev-Topics-EventsDue',
    template: '<p>This is events due subtopic.</p>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class EventsDueComponent implements OnInit {
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
}
