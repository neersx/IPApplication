import { ChangeDetectionStrategy, Component, Directive, ElementRef, Injector, Input } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';

@Directive({
    selector: 'ip-caseview-texts-upg'
})
export class CaseTextsDirective extends UpgradeComponent implements TopicContract {
    @Input() topic: CaseTextsTopic;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipCaseviewTextsWrapper', elementRef, injector);
    }
}

@Component({
    selector: 'ip-caseview-texts-component-upg',
    template: '<ip-caseview-texts-upg [(topic)]="topic"></ip-caseview-texts-upg>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseTextsComponent implements TopicContract {
    @Input() topic: CaseTextsTopic;
}

export class CaseTextsTopic extends Topic {
    readonly key = 'caseText';
    readonly title = caseViewTopicTitles.caseText;
    readonly component = CaseTextsComponent;
    constructor(public params: CaseTextsTopicParams) {
        super();
    }
}

export class CaseTextsTopicParams extends TopicParam {
    enableRichText: any;
    keepSpecHistory: any;
}
