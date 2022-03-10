import { ChangeDetectionStrategy, Component, Directive, ElementRef, EventEmitter, Injector, Input } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';

@Directive({
    selector: 'ip-caseview-images-upg'
})
export class CaseImagesDirective extends UpgradeComponent implements TopicContract {
    @Input() topic: CaseImagesTopic;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipCaseviewImagesWrapper', elementRef, injector);
    }
}

@Component({
    selector: 'ip-caseview-images-component-upg',
    template: '<ip-caseview-images-upg [(topic)]="topic"></ip-caseview-images-upg>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseImagesComponent implements TopicContract {
    @Input() topic: CaseImagesTopic;
}

export class CaseImagesTopic extends Topic {
    readonly key = 'images';
    readonly title = caseViewTopicTitles.images;
    setCount = new EventEmitter<number>();
    readonly component = CaseImagesComponent;
    constructor(public params: TopicParam) {
        super();
    }
}