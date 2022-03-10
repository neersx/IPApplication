import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ContentChild, ElementRef, EventEmitter, Input, NgZone, OnDestroy, OnInit, Output, QueryList, TemplateRef, ViewChild, ViewChildren } from '@angular/core';
import { StateService } from '@uirouter/core';
import { fromEvent } from 'rxjs';
import { map } from 'rxjs/operators';
import * as _ from 'underscore';
import { FocusService } from './../focus/focus.service';
import { IpxTopicResolverComponent } from './ipx-topic-resolver';
import { Topic, TopicOptions, TopicsAction, TopicType } from './ipx-topic.model';
import { TooltipTemplatesComponent } from './templates/tooltip-templates.component';

@Component({
  selector: 'ipx-topics',
  templateUrl: './ipx-topics.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    FocusService
  ]
})

export class IpxTopicsComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input() options: TopicOptions;
  @Input() type: TopicType;
  @Output() readonly activeTopicChanged = new EventEmitter<string>();
  @Output() readonly actionClicked = new EventEmitter<string>();
  @ViewChildren(IpxTopicResolverComponent) topicRefs: QueryList<IpxTopicResolverComponent>;
  @ViewChild(TooltipTemplatesComponent, { static: true }) tooltipTemplatesRef: TooltipTemplatesComponent;
  @ContentChild('afterHeader', { static: false }) afterTopicGroupHeaderTemplate: TemplateRef<any>;
  isSimpleTopic: Boolean;
  flattenTopics: Array<any> = [];
  currentTab: String = 'topics';
  isActionsTabVisible: Boolean = false;
  restrictWidth: Boolean = false;
  sensor: any;

  constructor(private readonly el: ElementRef, private readonly focusService: FocusService, private readonly state: StateService, private readonly ngZone: NgZone, private readonly cdr: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.isSimpleTopic =
      this.type === TopicType.Simple || this.type === TopicType.SimpleRestricted ? true : false;

    this.options.topics = this.filterNulls(this.options.topics);

    this.flatten(this.options.topics, this.flattenTopics);

    this.isActionsTabVisible = this.isActionsVisible();

    _.each(this.flattenTopics, (topic, index) => {
      topic.index = index;
      if (_.isFunction(topic.initialise)) {
        topic.initialise();
      }
      if (topic.topics) {
        topic.isGroupSection = true;
      } else {
        topic.isSubSection = true;
      }
    });

    _.each(this.flattenTopics, (topic, index) => {
      const next = this.flattenTopics[index + 1];
      if (!next || next.isGroupSection) {
        topic.noSeparator = true;
      }

      if (topic.setCount) {
        topic.setCount.subscribe((s: number) => {
          topic.count = s;
          this.cdr.markForCheck();
        });
      }
    });

    let selected = _.findWhere(this.flattenTopics, {
      isActive: true
    });
    if (selected) {
      this.ngZone.runOutsideAngular(() => {
        setTimeout(() => {
          let mostRecentScrollAmount: number = null;
          let currentSuccesses = 0;
          const scrollInterval = setInterval(() => {
            const newScroll = this.scrollToTopic(this.el.nativeElement, selected, true);
            if (newScroll !== mostRecentScrollAmount) {
              mostRecentScrollAmount = newScroll;
            } else {
              currentSuccesses++;
              if (currentSuccesses === 3) {
                clearInterval(scrollInterval);
              }
            }
          }, 1000);
        }, 2000);
      });
    } else {
      selected = _.first(this.options.topics);
      _.extend(selected, { isActive: true });
    }
  }

  ngAfterViewInit(): void {
    _.each(this.flattenTopics, (topic) => {
      if (!this.isSimpleTopic && topic.infoTemplateRef) {
        topic.templateResolved = typeof (topic.infoTemplateRef) === 'string'
          ? this.getTemplate(topic.infoTemplateRef)
          : topic.infoTemplateRef;
      }
    });

    const loadOnDemandTopics = this.topicRefs.filter((topicRef: any) => {
      return topicRef && topicRef.topicData.loadOnDemand;
    });

    const content = document.querySelector('.main-content-scrollable');
    if (!!content) {
      const scroll$ = fromEvent(content, 'scroll').pipe(map(() => content));
      if (!!scroll$) {
        scroll$.subscribe(() => {
          loadOnDemandTopics.map((t: IpxTopicResolverComponent) => {
            if (!t.topicData.loadedInView) {
              if (t.topicData.isInView()) {
                if (t.topicData.loadInView) {
                  t.topicData.loadInView();
                }
              }
            }
          });
        });
      }
    }
  }

  reloadTopics = (names: Array<string>) => {
    if (names && names.length > 0 && this.topicRefs && this.topicRefs.length > 0) {
      this.topicRefs.map((t: IpxTopicResolverComponent) => {
        if (t && t.topicData.component && names.indexOf(t.topicData.key) > -1) {
          t.reloadComponent();
        }
      });
    }
  };

  getTemplate(id: string): TemplateRef<any> {
    return this.tooltipTemplatesRef.templates.find((template: any) =>
      template.name === id);
  }

  ngOnDestroy(): any {
    if (this.sensor) {
      this.sensor.detach();
    }
  }

  filterNulls = (topics): any => {
    const compactTopics = _.compact(topics);

    _.each(compactTopics, (topic: any) => {
      if (topic.topics) {
        topic.topics = this.filterNulls(topic.topics);
      }
    });

    return compactTopics;
  };

  flatten = (topics, output): void => {
    _.each(topics, (topic: any) => {
      output.push(topic);
      if (topic.topics) {
        this.flatten(topic.topics, output);
      }
    });
  };

  selectTab = (tab): void => {
    this.currentTab = tab;
  };

  trackByDefault = (index: number, topic: any): string => {
    return topic;
  };

  private isActionsVisible(): boolean {
    return _.any(this.options.actions);
  }
  private mostRecentScroll: number;
  private scrollToTopic(rootElm, topic: Topic, shouldAnimate): number {
    const topicDiv = rootElm.querySelector('.topic-container[data-topic-key="' + topic.key + '"]');
    if (!topicDiv) {
      return null;
    }

    const scrollFixedTop = document.querySelector('ipx-sticky-header') ? document.querySelector('ipx-sticky-header').parentElement.clientHeight : 0;
    const adjustLength = rootElm.querySelector('ipx-topics div[name="topics"]');
    const scrollTop = topicDiv.offsetTop - (adjustLength.offsetTop + 5);
    const el = document.querySelector('ipx-topics div[name="topics"].main-content-scrollable');

    if (shouldAnimate && (this.mostRecentScroll !== scrollTop)) {
      el.scrollTop = scrollTop;
      this.mostRecentScroll = el.scrollTop;
    } else if (this.mostRecentScroll !== (scrollTop)) {
      setTimeout(() => {
        el.scrollTop = scrollTop - scrollFixedTop;
        this.mostRecentScroll = el.scrollTop;
      }, 100);
    }

    this.focusService.autoFocus(topicDiv);

    return el.scrollTop;
  }

  scrollToActive(): any {
    const activeTopic = _.findWhere(this.flattenTopics, {
      isActive: true
    });
    if (activeTopic) {
      this.scrollToTopic(this.el.nativeElement, activeTopic, false);
    }
    setTimeout(() => {
      this.sensor.detach();
    }, 5000);
  }

  selectTopic = (topic: Topic, scrollable: boolean): void => {
    _.each(this.flattenTopics, (t: any) => {
      t.isActive = false;
    });

    topic.isActive = true;
    this.activeTopicChanged.emit(topic.key);

    if (scrollable) {
      this.scrollToTopic(this.el.nativeElement, topic, true);
    }

    if (topic.loadOnDemand && !topic.loadedInView) {
      topic.loadInView();
    }
  };

  doAction = (action: TopicsAction) => {
    this.actionClicked.emit(action.key);
  };
}
