import { ChangeDetectionStrategy, Component, OnDestroy, OnInit } from '@angular/core';
import { AppContextService } from 'core/app-context.service';
import { BusService } from 'core/bus.service';
import { LocalSettings } from 'core/local-settings';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import { caseViewTopicTitles } from '../case-view-topic-titles';
import { CriticalDatesService } from './critical-dates.service';

@Component({
  selector: 'app-critical-dates',
  templateUrl: './critical-dates.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CriticalDatesComponent implements OnInit, OnDestroy, TopicContract {
  topic: CaseCriticalDatesTopic;
  viewData?: TopicViewData;

  isExternal = true;
  constructor(readonly appContext: AppContextService, readonly bus: BusService, readonly localSettings: LocalSettings, readonly service: CriticalDatesService) {
    this.appContext.appContext$.subscribe(context => this.isExternal = context.user.isExternal);
  }

  ngOnInit(): void {
    this.gridOptions = this.buildGridOptions();

    this.subscription = this.bus.channel('policingCompleted').subscribe(this.reloadData);
  }

  ngOnDestroy(): void {
    this.subscription.unsubscribe();
  }

  gridOptions: IpxGridOptions;
  private subscription: any;

  reloadData = () => {
    this.gridOptions._search();
  };

  buildGridOptions = (): IpxGridOptions => {

    const columns: Array<GridColumnDefinition> = [{
      title: '',
      sortable: false,
      field: 'isCpaRenewalDate',
      template: true,
      width: 38
    }, {
      title: 'caseview.criticalDates.date',
      field: 'date',
      template: true,
      width: 150
    }, {
      title: 'caseview.criticalDates.event',
      field: 'eventDescription',
      template: true
    }, {
      title: 'caseview.criticalDates.officialNo',
      sortable: true,
      field: 'officialNumber',
      template: true,
      width: 100
    }];

    return {
      autobind: true,
      pageable: false,
      reorderable: false,
      sortable: true,
      navigable: true,
      read$: (queryParams) => {
        return this.service.getDates(this.topic.params.viewData.caseKey, queryParams);
      },
      columns,
      columnSelection: {
        localSetting: this.localSettings.keys.caseView.criticalDates.datesColumnsSelection
      }
    };
  };

}

export class CaseCriticalDatesTopic extends Topic {
  readonly key = 'criticalDates';
  readonly title = caseViewTopicTitles.criticalDates;
  readonly component = CriticalDatesComponent;
  constructor(public params: TopicParam) {
    super();
  }
}