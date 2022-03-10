import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { map } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { NameViewTopicBaseComponent } from '../name-view-topics.base.component';
import { NameViewService } from '../name-view.service';
import { TrustAccountingDetailsComponent } from './trust-accounting-details.component';
@Component({
    selector: 'ipx-name-view-trust-accounting',
    templateUrl: './trust-accounting.html',
    styleUrls: ['./trust-accounting.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class TrustAccountingComponent extends NameViewTopicBaseComponent implements TopicContract, OnInit {
    gridOptions: IpxGridOptions;
    topic: Topic;
    localBalanceTotal: number;
    showWebLink: boolean | false;
    isHosted: boolean;

    constructor(private readonly service: NameViewService, private readonly cdr: ChangeDetectorRef, private readonly modalService: IpxModalService, private readonly localSettings: LocalSettings) {
        super(cdr);
    }

    ngOnInit(): void {
        this.onInit();
        this.isHosted = this.topic.params.viewData.hostId === 'trustHost';
        this.showWebLink = (this.topic.params as TrustAccountingTopicParams).showWebLink;
        this.localBalanceTotal = 0;
        this.gridOptions = this.buildGridOptions();
    }

    private readonly buildGridOptions = (): IpxGridOptions => {

        return {
          selectable: {
            mode: 'single'
          },
          sortable: true,
          autobind: true,
          columnSelection: {
            localSetting: this.localSettings.keys.nameView.trustAccounting.columnsSelection
          },
          read$: (queryParams: GridQueryParameters) => {
            return this.service.getTrustAccounting$(this.viewData.nameId, queryParams)
              .pipe(map((resultData: any) => {
                this.localBalanceTotal = resultData.totalLocalBalance;

                return resultData.result;
              }
              ));
          },
          columns: this.getColumns(),
          persistSelection: false,
          reorderable: true,
          navigable: false,
          pageable: {
            pageSizeSetting: this.localSettings.keys.nameView.trustAccounting.pageNumber
          }
        };
      };

      private readonly getColumns = (): Array<GridColumnDefinition> => {
        const columns = [
          {
            title: 'nameview.trustAccounting.entity',
            field: 'entity',
            template: true,
            width: 500
          },
          {
            title: 'nameview.trustAccounting.bankAccount',
            field: 'bankAccount',
            template: true,
            width: 500
          },
          {
            title: 'nameview.trustAccounting.localBalance',
            field: 'localBalance',
            template: true,
            headerClass: 'k-header-right-aligned',
            width: 110
          },
          {
            title: 'nameview.trustAccounting.foreignBalance',
            field: 'foreignBalance',
            template: true,
            headerClass: 'k-header-right-aligned',
            width: 110
          }];

        return columns;
      };

      encodeLinkData = (data: any) => {
        return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({
          nameKey: data
        }));
      };

      openTrustDetails = (data: any): void => {
          this.modalService.openModal(TrustAccountingDetailsComponent, {
              animated: false,
              backdrop: 'static',
              class: 'modal-xl',
              initialState: {
                  nameId: this.viewData.nameId,
                  bankId: data.bankAccountNameKey,
                  bankSeqId: data.bankAccountSeqKey,
                  entityId: data.entityKey,
                  entityName: data.entity,
                  bankAccount: data.bankAccount
              }
          });
      };
}

export class TrustAccountingTopic extends Topic {
    readonly key = 'trustAccounting';
    readonly title = 'nameview.trustAccounting.header';
    readonly component = TrustAccountingComponent;
    constructor(public params: TrustAccountingTopicParams) {
      super();
    }
}

export class TrustAccountingTopicParams extends TopicParam {
  showWebLink: boolean;
}