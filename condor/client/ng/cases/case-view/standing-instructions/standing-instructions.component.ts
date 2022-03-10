import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { CaseDetailService } from '../case-detail.service';

@Component({
  selector: 'app-standing-instructions',
  templateUrl: './standing-instructions.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class StandingInstructionsComponent implements OnInit {
  @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
  gridOptions: IpxGridOptions;
  topic: Topic;
  showWebLink: boolean | false;

  ngOnInit(): void {
    this.gridOptions = this.buildGridOptions();
    this.showWebLink = (this.topic.params as StandingInstructionsParams).showWebLink;
  }

  buildGridOptions = (): IpxGridOptions => {
    return {
      manualOperations: true,
      selectable: {
        mode: 'single'
      },
      sortable: true,
      autobind: true,
      read$: () => this.service.getStandingInstructions$(this.topic.params.viewData.caseId),
      detailTemplate: this.detailTemplate,
      columns: this.getColumns(),
      persistSelection: false,
      reorderable: true,
      navigable: false,
      onDataBound: (data: any) => {
        if (data) {
          this.topic.setCount.emit(data.length);
        }
      },
      sort: [{
        field: 'instructionType',
        dir: 'asc'
      }]
    };
  };

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    const columns = [
      {
        title: 'caseview.standingInstructions.instructionType',
        field: 'instructionType',
        sortable: true,
        width: 130
      },
      {
        title: 'caseview.standingInstructions.instruction',
        field: 'instruction',
        sortable: true,
        width: 170
      },
      {
        title: 'caseview.standingInstructions.defaultedFrom',
        field: 'defaultedFrom',
        template: true,
        sortable: true,
        width: 170
      },
      {
        title: 'caseview.standingInstructions.period1',
        field: 'period1',
        template: true,
        sortable: false,
        width: 70
      },
      {
        title: 'caseview.standingInstructions.period2',
        field: 'period2',
        template: true,
        sortable: false,
        width: 70
      },
      {
        title: 'caseview.standingInstructions.period3',
        field: 'period3',
        template: true,
        sortable: false,
        width: 70
      }];

    return columns;
  };

  encodeLinkData = (data: any) => {
    return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({
      nameKey: data
    }));
  };

  constructor(private readonly service: CaseDetailService) {
  }
}

export class StandingInstructionsTopic extends Topic {
  readonly key = 'caseStandingInstructions';
  readonly title = 'caseview.standingInstructions.header';
  readonly component = StandingInstructionsComponent;
  readonly setCount = new EventEmitter<number>();
  constructor(public params: StandingInstructionsParams) {
    super();
  }
}

export class StandingInstructionsParams extends TopicParam {
  showWebLink: boolean;
}