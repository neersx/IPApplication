import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { IppAvailability } from '../case-detail.service';
import { caseViewTopicTitles } from '../case-view-topic-titles';
import { RelatedCasesService } from './related-cases.service';

@Component({
  selector: 'ipx-caseview-related-cases',
  templateUrl: './related-cases.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RelatedCasesComponent implements OnInit, TopicContract {
  @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
  topic: Topic;
  gridOptions: IpxGridOptions;
  isExternal = true;
  ippAvailability: IppAvailability;
  constructor(readonly localSettings: LocalSettings, readonly service: RelatedCasesService) { }

  ngOnInit(): void {
    this.ippAvailability = (this.topic.params as CaseRelatedCasesTopicParams).ippAvailability;
    this.isExternal = (this.topic.params as CaseRelatedCasesTopicParams).isExternal;
    this.gridOptions = {
      autobind: true,
      pageable: {
        pageSizeSetting: this.localSettings.keys.caseView.relatedCases.pageNumber,
        pageSizes: [10, 20, 50, 100, 250]
      },
      navigable: true,
      sortable: true,
      reorderable: true,
      detailTemplate: this.detailTemplate,
      detailTemplateShowCondition: (dataItem) => dataItem.eventDescription || dataItem.title || dataItem.cycle,
      read$: (queryParams) => {
        return this.service.getRelatedCases(this.topic.params.viewData.caseKey, queryParams);
      },
      onDataBound: (data: any) => {
        if (data && data.total) {
          this.topic.setCount.emit(data.total);
        }
      },
      columns: this.getColumns(),
      columnSelection: {
        localSetting: this.localSettings.keys.caseView.relatedCases.columnsSelection
      }
    };
  }

  getColumns = (): Array<GridColumnDefinition> => {
    const columns: Array<GridColumnDefinition> = [{
      title: '',
      field: 'direction',
      fixed: true,
      width: 15,
      menu: false,
      sortable: true,
      template: true
    }, {
      title: 'caseview.relatedCases.relationship',
      field: 'relationship'
    }, {
      title: this.isExternal ? 'caseview.relatedCases.caseReferenceExternal' : 'caseview.relatedCases.caseReference',
      field: 'internalReference',
      template: true
    }, {
      title: 'caseview.relatedCases.officialNumber',
      field: 'officialNumber',
      template: true
    }, {
      title: 'caseview.relatedCases.jurisdiction',
      field: 'jurisdiction'
    }, {
      title: 'caseview.relatedCases.date',
      field: 'eventDate',
      template: true
    }, {
      title: 'caseview.relatedCases.status',
      field: 'status'
    }, {
      title: 'caseview.relatedCases.classes',
      field: 'classes'
    }];

    if (this.isExternal) {
      columns.splice(2, 0, {
        title: 'caseview.relatedCases.clientReference',
        field: 'clientReference',
        template: true
      });
    }

    if (this.ippAvailability.file.isEnabled && this.ippAvailability.file.hasViewAccess) {
      columns.unshift({
        width: 40,
        title: '',
        field: 'isFiled',
        sortable: false,
        fixed: true,
        template: true
      });
    }

    return columns;
  };
}

export class CaseRelatedCasesTopicParams extends TopicParam {
  isExternal: boolean;
  ippAvailability: IppAvailability;
}
export class CaseRelatedCasesTopic extends Topic {
    readonly key = 'relatedCases';
    readonly title = caseViewTopicTitles.relatedCases;
    readonly component = RelatedCasesComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: CaseRelatedCasesTopicParams) {
      super();
    }
}