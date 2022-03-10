import { ChangeDetectionStrategy, Component, Directive, ElementRef, Injector, Input } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';

@Directive({
    selector: 'ip-caseview-names-upg'
})
export class CaseNamesDirective extends UpgradeComponent implements TopicContract {
    @Input() topic: CaseNamesTopic;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipCaseviewNamesWrapper', elementRef, injector);
    }
}

@Component({
    selector: 'ip-caseview-names-component-upg',
    template: '<ip-caseview-names-upg [(topic)]="topic"></ip-caseview-names-upg>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseNamesComponent implements TopicContract {
    @Input() topic: CaseNamesTopic;
}

export class CaseNamesTopic extends Topic {
    readonly key = 'names';
    readonly title = caseViewTopicTitles.names;
    readonly component = CaseNamesComponent;
    constructor(public params: CaseNamesTopicParams) {
        super();
    }
}

export class CaseNamesTopicParams extends TopicParam {
    isExternal: boolean;
    showWebLink: boolean;
    screenCriteriaKey?: number;
}
