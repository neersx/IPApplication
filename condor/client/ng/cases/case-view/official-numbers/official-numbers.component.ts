import { ChangeDetectionStrategy, Component, EventEmitter, OnInit } from '@angular/core';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { Topic, TopicGroup, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { caseViewTopicTitles } from '../case-view-topic-titles';
import { OfficialNumbersService } from './official-numbers.service';

@Component({
  selector: 'ipx-caseview-official-numbers',
  templateUrl: './official-numbers.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OfficialNumbersComponent implements OnInit {
  private readonly availableOfficialNumberTypes = {
    ipOffice: 'ipOffice',
    other: 'other'
  };
  constructor(readonly service: OfficialNumbersService) { }
  gridOptions: IpxGridOptions;
  officialNumberType: string;
  ngOnInit(): void {
    this.officialNumberType = (this.topic.params as CaseOfficialNumbersTopicParams).officialNumberType;
    this.gridOptions = this.buildGridOptions();
  }
  topic: Topic;

  buildGridOptions = (): IpxGridOptions => {
    return {
      navigable: true,
      pageable: false,
      read$: this.search,
      onDataBound: (data: any) => {
        if (data && data.length) {
          this.topic.setCount.emit(data.length);
        }
      },
      columns: [{
        sortable: true,
        title: 'caseview.officialNumbers.numberType',
        field: 'numberTypeDescription'
      }, {
        sortable: true,
        title: this.officialNumberTitle(),
        field: 'officialNumber',
        template: true,
        width: 300
      },
      {
        sortable: true,
        title: 'caseview.officialNumbers.dateInForce',
        field: 'dateInForce',
        width: 250,
        template: true
      }, {
        sortable: true,
        title: 'caseview.officialNumbers.isCurrent',
        field: 'isCurrent',
        width: 250,
        template: true
      }]
    };
  };

  private readonly search = (queryParams) => {
    if (this.officialNumberType === this.availableOfficialNumberTypes.ipOffice) {
      return this.service.getCaseViewIpOfficeNumbers(this.topic.params.viewData.caseKey, queryParams);
    }

    return this.service.getCaseViewOtherNumbers(this.topic.params.viewData.caseKey, queryParams);
  };

  private readonly officialNumberTitle = () => {
    if (this.officialNumberType === this.availableOfficialNumberTypes.ipOffice) {
      return 'caseview.officialNumbers.officialNumber';
    }

    return 'caseview.officialNumbers.reference';
  };
}

export class OfficialNumbersGroupTopic extends TopicGroup {
  readonly key = 'officialNumbers';
  readonly title = caseViewTopicTitles.officialNumbers;
  readonly topics: Array<Topic>;
  constructor(public params: TopicParam, canViewOtherNumbers: boolean) {
    super();
    this.topics = [
      new CaseOfficialNumbersTopic('iPOfficeNumbers', 'caseview.officialNumbers.iPOfficeNumbers', {
        viewData: params.viewData,
        officialNumberType: 'ipOffice'
      })
    ];
    if (canViewOtherNumbers) {
      this.topics.push(new CaseOfficialNumbersTopic('otherNumbers', 'caseview.officialNumbers.otherNumbers', {
        viewData: params.viewData,
        officialNumberType: 'other'
      }));
    }
  }
}
export class CaseOfficialNumbersTopic extends Topic {
  readonly component = OfficialNumbersComponent;
  readonly setCount = new EventEmitter<number>();
  constructor(public key: string, public title: string, public params: CaseOfficialNumbersTopicParams) {
    super();
  }
}

export class CaseOfficialNumbersTopicParams extends TopicParam {
  officialNumberType: string;
}