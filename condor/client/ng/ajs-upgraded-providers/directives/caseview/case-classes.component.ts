import { ChangeDetectionStrategy, Component, Directive, ElementRef, Injector, Input } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';

@Directive({
    selector: 'ip-caseview-classes-upg'
})
export class CaseClassesDirective extends UpgradeComponent implements TopicContract {
    @Input() topic: CaseClassesTopic;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipCaseviewClassesWrapper', elementRef, injector);
    }
}

@Component({
    selector: 'ip-caseview-classes-component-upg',
    template: '<ip-caseview-classes-upg [(topic)]="topic"></ip-caseview-classes-upg>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseClassesComponent implements TopicContract {
    @Input() topic: CaseClassesTopic;
}

export class CaseClassesTopic extends Topic {
    readonly key = 'actions';
    readonly title = caseViewTopicTitles.classes;
    readonly component = CaseClassesComponent;
    constructor(public params: CaseClassTopicParams) {
        super();
    }
}

export class CaseClassTopicParams extends TopicParam {
    enableRichText: any;
}
