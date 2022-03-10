import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { StateService } from '@uirouter/angular';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import { ScreenDesignerCriteriaDetails, ScreenDesignerCriteriaViewData, ScreenDesignerService } from '../../screen-designer.service';
import { SearchService } from '../search/search.service';
import { CharacteristicsSummaryComponent } from './characteristics-summary/characteristics-summary.component';
import { ScreenDesignerSectionsComponent } from './sections/screen-designer-sections.component';

@Component({
  selector: 'ipx-screendesigner-cases-maintenance',
  templateUrl: './maintenance.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MaintenanceComponent implements OnInit {
  topic: Topic;
  @Input() viewData: ScreenDesignerCriteriaViewData;
  @Input() stateParams: {
    id: number,
    rowKey: string,
    levelUpState: string
  };
  hasPreviousState = false;
  topicOptions: TopicOptions;
  navigationState: string;
  @Input() screenCriteriaDetails: ScreenDesignerCriteriaDetails;
  navData: any;
  constructor(private readonly searchService: SearchService,
    private readonly state: StateService,
    private readonly screenDesignerService: ScreenDesignerService) {
    this.navigationState = this.state.current.name;
    this.navData = searchService.getNavData();
  }

  activeTopicChanged(topicKey: string): void {
    this.searchService.setSelectedTopic(topicKey);
  }

  beforeLevelUp = (): void => {
    this.screenDesignerService.popState();
  };

  navigateToInheritance = (): void => {
    this.screenDesignerService.pushState({ id: this.stateParams.id, stateName: 'screenDesignerCaseCriteria' });
    this.state.go('screenDesignerCaseInheritance', { id: this.stateParams.id, rowKey: this.stateParams.rowKey });
  };

  ngOnInit(): void {
    if (this.stateParams.rowKey || this.screenDesignerService.previousState()) {
      this.hasPreviousState = true;
    }

    this.topicOptions = {
      topics: [
        {
          key: 'characteristics',
          title: 'Characteristics',
          component: CharacteristicsSummaryComponent,
          params: {
            viewData: {
              viewData: this.viewData,
              criteriaData: this.screenCriteriaDetails
            }
          }
        },
        {
          key: 'sections',
          title: 'screenDesignerCases.criteriaMaintenance.criteriaSections.title', // Translate THese
          component: ScreenDesignerSectionsComponent,
          params: {
            viewData: {
              criteriaData: this.screenCriteriaDetails
            }
          }
        }
      ]
    };
    const selectedTopic = this.searchService.getSelectedTopic();
    if (selectedTopic) {
      const isActive = (topic): boolean => {
        return (topic.key && (topic.key.split('_')[0]).toLowerCase() === selectedTopic.toLowerCase());
      };
      this.topicOptions.topics.forEach(topic => {
        topic.isActive = isActive(topic);
        (topic.topics || []).forEach((subTopic: any) => {
          subTopic.isActive = isActive(subTopic);
        });
      });
    }
  }

}
