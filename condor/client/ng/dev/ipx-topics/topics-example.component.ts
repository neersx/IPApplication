import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { TopicOptions } from 'shared/component/topics/ipx-topic.model';
import { CharacteristicsComponent } from './characteristics.component';
import { EventsComponent } from './events.component';
import { EventsDueComponent } from './events.due.component';
import { EventsOccuredComponent } from './events.occured.component';
import { ReferencesComponent } from './references.component';

@Component({
  selector: 'topics',
  templateUrl: './topics-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TopicsExampleComponent implements OnInit {
  options: TopicOptions;

  ngOnInit(): void {
    this.options = {
      topics: [
        {
          key: 'chars',
          title: 'Characteristics',
          infoTemplateRef: 'nameChangePopoverRef',
          component: CharacteristicsComponent,
          params: {
            viewData: {
              isExternal: false,
              numberTypes: true,
              nameTypes: false
            }
          }
        },
        {
          key: 'events',
          title: 'Event Control',
          component: EventsComponent,
          info: 'Example topic page.'
        },
        {
          key: 'ref',
          title: 'References',
          component: ReferencesComponent,
          params: {
            viewData: {
              isExternal: false,
              numberTypes: true,
              nameTypes: false
            }
          }
        },
        {
          key: 'eventsGroup',
          title: 'caseview.events.header',
          topics: [{
            key: 'due',
            title: 'caseview.events.due',
            component: EventsDueComponent,
            infoTemplateRef: 'eventOccurrenceRef',
            params: {
              viewData: { subTopicParam: 'topicParam1' }
            }
          }, {
            key: 'occurred',
            title: 'caseview.events.occurred',
            component: EventsOccuredComponent,
            params: {
              viewData: { subTopicParam: 'topicParam1' }
            },
            info: 'Sub topic info'
          }]
        }
      ],
      actions: [
        {
          key: 'criteriaNumber',
          title: 'Criteria Number',
          tooltip: 'Criteria Number info tooltip'
        },
        {
          key: 'resetCriteria',
          title: 'Reset Criteria'
        }
      ]
    };
  }
}
