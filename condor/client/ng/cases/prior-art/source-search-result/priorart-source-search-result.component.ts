import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnChanges, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { delay, map, take } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { PriorArtDetailsComponent } from '../priorart-details/priorart-details.component';
import { PriorartMaintenanceHelper } from '../priorart-maintenance/priorart-maintenance-helper';
import { PriorArtOrigin, PriorArtSearch, PriorArtSearchType } from '../priorart-search/priorart-search-model';
import { PriorArtService } from '../priorart.service';

@Component({
  selector: 'ipx-priorart-source-search-result',
  templateUrl: './priorart-source-search-result.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class PriorartSourceSearchResultComponent implements OnInit, OnChanges {
  @ViewChild('dataDetailTemplate', { static: true }) dataDetailTemplate: TemplateRef<any>;
  @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
  @ViewChild('dataDetailComponent', { static: false }) dataDetailComponent: PriorArtDetailsComponent;
  @Input() searchData: PriorArtSearch;
  @Input() hidePriorArtStatus: boolean | false;
  @Input() hasIpd1Error: boolean | false;
  @Input() translationsList: any = {};
  @Output() readonly onRefreshGrid = new EventEmitter();
  gridOptions: IpxGridOptions;
  originIpOne: any;
  originInprotech: any;
  expandFirstRowOnRefresh = false;
  constructor(private readonly service: PriorArtService,
    private readonly notificationService: IpxNotificationService,
    private readonly successNotificationService: NotificationService,
    private readonly cdr: ChangeDetectorRef,
    readonly localSettings: LocalSettings
  ) { }

  ngOnInit(): void {
    this.originIpOne = PriorArtOrigin.OriginIpOne;
    this.originInprotech = PriorArtOrigin.OriginInprotechPriorArt;
    this.gridOptions = this.buildGridOptions();
  }

  ngOnChanges(): void {
    if (!!this.grid) {
      this.grid.search();
    }
  }

  buildGridOptions(): IpxGridOptions {
    const pageSizeSetting = this.localSettings.keys.priorart.search.sourcePageSize;

    return {
      sortable: true,
      selectable: {
        mode: 'single'
      },
      autobind: true,
      read$: (queryParams) => {
        this.searchData.queryParameters = queryParams;

        return this.service.getSearchedData$(this.searchData, queryParams).pipe(delay(100), map(data => {
          const inprotechDataSet = _.find(data.result, (t: any) => {
            return t.source === PriorArtSearchType.ExistingPriorArtFinder;
          });

          return inprotechDataSet !== undefined ? inprotechDataSet.matches : null;
        }));
      },
      columns: this.getColumns(),
      persistSelection: false,
      reorderable: true,
      navigable: false,
      onDataBound: () => {
        if (this.expandFirstRowOnRefresh) {
          this.grid.collapseAll();
          this.grid.navigateByIndex(0);
          this.grid.wrapper.expandRow(0);
          this.expandFirstRowOnRefresh = false;
        }
      },
      customRowClass: (context) => {
        if (context.dataItem.isSaved) {
          return 'saved';
        }

        return '';
      },
      pageable: {
        pageSizeSetting,
        pageSizes: [20, 50, 100, 200]
      }
    };
  }

  onSaveData(event): void {
    if (event.success) {
      this.successNotificationService.success();
    }
  }

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    const columns: Array<GridColumnDefinition> = [
      {
        title: 'priorart.sourceType',
        field: 'sourceType',
        template: true,
        sortable: true,
        width: 150
      },
      {
        title: 'priorart.issuingJurisdiction',
        field: 'issuingJurisdiction',
        template: false,
        sortable: true,
        width: 150
      },
      {
        title: 'priorart.description',
        field: 'description',
        template: false,
        sortable: true,
        width: 400
      },
      {
        title: 'priorart.publication',
        field: 'publication',
        template: false,
        sortable: true,
        width: 200
      },
      {
        title: 'priorart.reportIssued',
        field: 'reportIssued',
        template: false,
        sortable: true,
        type: 'date',
        defaultColumnTemplate: DefaultColumnTemplateType.date,
        width: 100
      },
      {
        title: 'priorart.reportReceived',
        field: 'reportReceived',
        template: false,
        sortable: true,
        type: 'date',
        defaultColumnTemplate: DefaultColumnTemplateType.date,
        width: 100
      },
      {
        title: 'priorart.comments',
        field: 'comments',
        template: false,
        sortable: true,
        width: 200
      },
      {
        title: 'priorart.classes',
        field: 'classes',
        template: false,
        sortable: true,
        width: 80
      },
      {
        title: 'priorart.subClasses',
        field: 'subClasses',
        template: false,
        sortable: true,
        width: 80
      }];
    if (!this.hidePriorArtStatus) {
      columns.push(
        {
          title: 'priorart.status',
          field: 'priorArtStatus',
          template: false,
          sortable: true,
          width: 200
        });
    }
    columns.push(
        {
            title: '',
            field: 'canEdit',
            template: true,
            sortable: false,
            width: 10
        },
        {
        title: '',
        field: 'buttons',
        template: true,
        sortable: false,
        width: 10
      });

    return columns;
  };

  onCollapse(event): void {
    if (event.dataItem.hasChanges) {
      event.prevented = true;
      const modal = this.notificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.dataDetailComponent.revertForm(event);
          event.dataItem.hasChanges = false;
          const collapseElement = this.grid.wrapper.wrapper.nativeElement.querySelector('.k-hierarchy-cell .k-minus');
          if (collapseElement) {
            collapseElement.click();
          }
        });
    }
  }

  cite(dataItem: any): void {
    this.service.citeSourceDocument$(dataItem.id, this.searchData.sourceDocumentId, this.searchData.caseKey)
      .subscribe(() => {
        dataItem.isCited = true;
        this.successNotificationService.success('priorart.citedMessage');
        if (!!this.dataDetailComponent) {
          this.dataDetailComponent.resetForm();
        }
        this.cdr.detectChanges();
      });
  }

    edit = (dataItem: any): void => {
        PriorartMaintenanceHelper.openMaintenance(dataItem, this.searchData.caseKey);
    };
}