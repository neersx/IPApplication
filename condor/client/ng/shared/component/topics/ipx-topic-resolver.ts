import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ComponentFactoryResolver, ElementRef, Input, OnInit, ViewChild, ViewContainerRef } from '@angular/core';
import { MaintenanceTopicContract } from 'cases/case-view/base/case-view-topics.base.component';
import { IpxTopicHostDirective } from './ipx-topic-host.directive';
import { TopicContract } from './ipx-topic.contract';
import { Topic } from './ipx-topic.model';

@Component({
    selector: 'ipx-topic-resolver',
    template: '<ng-template topic-host></ng-template>',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxTopicResolverComponent implements OnInit {
    @Input() topicData: Topic;
    @ViewChild(IpxTopicHostDirective, { static: true }) topicHost: IpxTopicHostDirective;
    componentInstance: TopicContract | MaintenanceTopicContract;
    constructor(private readonly componentFactoryResolver: ComponentFactoryResolver, private readonly el: ElementRef, private readonly cdr: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.loadComponent();
    }

    loadComponent(): void {
        const componentFactory = this.componentFactoryResolver.resolveComponentFactory(this.topicData.component);

        const viewContainerRef = this.topicHost.viewContainerRef;
        viewContainerRef.clear();

        const componentRef = viewContainerRef.createComponent(componentFactory);

        this.componentInstance = componentRef.instance as TopicContract;
        this.componentInstance.topic = this.topicData;
    }

    reloadComponent = (): void => {
        if (this.componentInstance && this.componentInstance.reloadData) {
            this.componentInstance.reloadData();
        }
        this.cdr.markForCheck();
    };
}
