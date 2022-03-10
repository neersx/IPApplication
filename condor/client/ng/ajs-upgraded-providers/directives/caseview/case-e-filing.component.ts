import { ChangeDetectionStrategy, Component, Directive, ElementRef, Injector, Input } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';

@Directive({
    selector: 'ip-caseview-e-filing-upg'
})
export class CaseEFilingDirective extends UpgradeComponent implements TopicContract {
    @Input() topic: CaseEFilingTopic;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipCaseviewEFilingWrapper', elementRef, injector);
    }
}

@Component({
    selector: 'ip-caseview-e-filing-component-upg',
    template: '<ip-caseview-e-filing-upg [(topic)]="topic"></ip-caseview-e-filing-upg>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseEFilingComponent implements TopicContract {
    @Input() topic: CaseEFilingTopic;
}

export class CaseEFilingTopic extends Topic {
    readonly key = 'eFiling';
    readonly title = caseViewTopicTitles.eFiling;
    readonly component = CaseEFilingComponent;
    constructor(public params: TopicParam) {
        super();
    }
}