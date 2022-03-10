import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { map } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { NameViewService } from '../name-view.service';
@Component({
    selector: 'ipx-trust-accounting-details',
    templateUrl: './trust-accounting-details.html',
    styleUrls: ['./trust-accounting.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class TrustAccountingDetailsComponent implements OnInit {
    nameId: Number;
    bankId: Number;
    bankSeqId: Number;
    entityId: Number;
    entityName: string;
    bankAccount: string;
    gridOptions: IpxGridOptions;
    localBalanceTotal: number;
    localValueTotal: number;

    constructor(private readonly bsModalRef: BsModalRef, private readonly service: NameViewService, private readonly localSettings: LocalSettings) {}

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.localBalanceTotal = 0;
        this.localValueTotal = 0;
    }

    buildGridOptions(): IpxGridOptions {
        return {
            selectable: {
                mode: 'single'
            },
            sortable: true,
            autobind: true,
            columnSelection: {
              localSetting: this.localSettings.keys.nameView.trustAccountingDetails.columnsSelection
            },
            read$: (queryParams: GridQueryParameters) => {
              return this.service.getTrustAccountingDetails$(this.nameId, this.bankId, this.bankSeqId, this.entityId, queryParams)
                .pipe(map((resultData: any) => {
                  this.localBalanceTotal = resultData.totalLocalBalance;
                  this.localValueTotal = resultData.totalLocalValue;

                  return resultData.result;
                }
                ));
            },
            columns: this.getColumns(),
            persistSelection: false,
            reorderable: true,
            navigable: false,
            pageable: {
              pageSizeSetting: this.localSettings.keys.nameView.trustAccountingDetails.pageNumber
            }
        };
    }

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const columns = [
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.date',
            field: 'date',
            template: true
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.itemrefno',
            field: 'itemrefno',
            template: true
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.referenceno',
            field: 'referenceno',
            template: true
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.localvalue',
            field: 'localvalue',
            template: true,
            headerClass: 'k-header-right-aligned'
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.localbalance',
            field: 'localbalance',
            template: true,
            headerClass: 'k-header-right-aligned'
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.foreignvalue',
            field: 'foreignvalue',
            template: true,
            headerClass: 'k-header-right-aligned'
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.foreignbalance',
            field: 'foreignbalance',
            template: true,
            headerClass: 'k-header-right-aligned'
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.exchangedifference',
            field: 'exchvariance',
            template: true,
            headerClass: 'k-header-right-aligned'
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.trader',
            field: 'trader',
            template: true,
            width: 200
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.transactiontype',
            field: 'transtype',
            template: true
          },
          {
            title: 'nameview.trustAccounting.trustAccountingDetails.description',
            field: 'description',
            template: true,
            width: 200
          }];

        return columns;
      };

    close(): void {
        this.bsModalRef.hide();
    }
}