import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Directive, ElementRef, EventEmitter, Injector, Input, OnDestroy, OnInit } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { BusService } from 'core/bus.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';

@Directive({
    selector: 'ip-caseview-summary-upg'
})

export class CaseSummaryDirective extends UpgradeComponent implements TopicContract {
    @Input() topic: CaseSummaryTopic;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipCaseviewSummaryWrapper', elementRef, injector);
    }
}

@Component({
    selector: 'ip-caseview-summary-component-upg',
    template: '<ip-caseview-summary-upg *ngIf="!dontShow" [(topic)]="topic"></ip-caseview-summary-upg>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseSummaryComponent implements TopicContract, OnInit, OnDestroy {
    dontShow: boolean;
    constructor(readonly cdr: ChangeDetectorRef, readonly bus: BusService) {
    }
    subscription: any;
    ngOnInit(): void {
        this.subscription = this.bus.channel('viewDataChanged').subscribe(this.reload);
    }

    ngOnDestroy(): void {
        this.subscription.unsubscribe();
    }

    reload = (viewData): void => {
        this.dontShow = true;
        this.cdr.markForCheck();

        setTimeout(() => {
            this.topic = {
                ...this.topic,
                params: {
                    ...this.topic.params,
                    viewData
                }
            };
            this.dontShow = false;
            this.cdr.markForCheck();
        }, 0);
    };

    @Input() topic: CaseSummaryTopic;
}

export class CaseSummaryTopic extends Topic {
    readonly key = 'summary';
    readonly title = caseViewTopicTitles.summary;
    readonly component = CaseSummaryComponent;
    constructor(public params: CaseSummaryTopicParams) {
        super();
    }
}

export class CaseSummaryTopicParams extends TopicParam {
    showWebLink: boolean;
    screenControl: any;
    hasScreenControl: boolean;
    withImage: boolean;
    isExternal: boolean;
}