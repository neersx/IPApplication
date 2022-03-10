import { ChangeDetectionStrategy, Component, Directive, ElementRef, Injector, Input } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicGroup, TopicParam } from 'shared/component/topics/ipx-topic.model';

@Directive({
    selector: 'ip-caseview-events-upg'
})
export class CaseEventsDirective extends UpgradeComponent implements TopicContract {
    @Input() topic: Topic;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipCaseviewEventsWrapper', elementRef, injector);
    }
}

@Component({
    selector: 'ip-caseview-events-component-upg',
    template: '<ip-caseview-events-upg [(topic)]="topic"></ip-caseview-events-upg>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseEventsComponent implements TopicContract {
    @Input() topic: Topic;
}