import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit } from '@angular/core';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { ViewPortService } from './../../../shared/shared-services/view-port.service';

@Component({
  selector: 'custom-content',
  templateUrl: './custom-content.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CustomContentComponent implements TopicContract, OnInit, AfterViewInit {
  topic: Topic;
  contentUrl: string;
  parentAccessAllowed: boolean;

  constructor(private readonly elementRef: ElementRef,
                 private readonly cdRef: ChangeDetectorRef,
                 private readonly viewPortService: ViewPortService) {}

  ngOnInit(): void {
    _.extend(this.topic, {
      isInView: this.isInView,
      loadInView: this.loadInView,
      loadedInView: false
    });
    this.parentAccessAllowed = this.topic.filters.parentAccessAllowed === 'True' ? true : false;
  }

  ngAfterViewInit(): void {
    const isInView = this.isInView();
    if (isInView) {
      this.loadInView();
    }
  }

  isInView = (): Boolean => {
    return this.viewPortService.isInView(this.elementRef);
  };

  loadInView = () => {
    this.contentUrl = decodeURIComponent(this.topic.filters.customContentUrl);
    this.topic.loadedInView = true;
    this.cdRef.markForCheck();
  };
}

export class CustomContentTopic extends Topic {
  readonly key = 'caseCustomContent';
  readonly title = 'Custom Content';
  readonly filters: any;
  readonly component = CustomContentComponent;
  readonly loadOnDemand: Boolean = true;

  constructor(public params: TopicParam) {
    super();
  }
}