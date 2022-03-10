import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnChanges, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
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
import { PriorArtOrigin, PriorArtSearch, PriorArtSearchResult, PriorArtSearchType } from '../priorart-search/priorart-search-model';
import { PriorArtService } from '../priorart.service';

@Component({
  selector: 'ipx-literature-search-result',
  templateUrl: './literature-search-result.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class LiteratureSearchResultComponent implements OnInit, OnChanges {
  @ViewChild('dataDetailTemplate', { static: true }) dataDetailTemplate: TemplateRef<any>;
  @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
  @ViewChild('dataDetailComponent', { static: false }) dataDetailComponent: PriorArtDetailsComponent;
  @ViewChild('dataLiteratureDetailComponent', { static: false }) dataLiteratureDetailComponent: PriorArtDetailsComponent;
  @Input() searchData: PriorArtSearch;
  @Input() enableCiting: boolean | false;
  @Input() translationsList: any = {};
  @Output() readonly onRefreshGrid = new EventEmitter();
  gridOptions: IpxGridOptions;
  originIpOne: any;
  originInprotech: any;
  details: any;
  expandFirstRowOnRefresh = false;
  showAddNewLiterature = false;
  itemName: string;
  constructor(private readonly service: PriorArtService,
    private readonly notificationService: IpxNotificationService,
    private readonly successNotificationService: NotificationService,
    private readonly cdr: ChangeDetectorRef,
    readonly localSettings: LocalSettings,
    private readonly translate: TranslateService
  ) { }

  ngOnInit(): void {
    this.originIpOne = PriorArtOrigin.OriginIpOne;
    this.originInprotech = PriorArtOrigin.OriginInprotechPriorArt;
    this.gridOptions = this.buildGridOptions();
    const newPriorArtSearch = new PriorArtSearchResult();
    // tslint:disable-next-line: strict-boolean-expressions
    newPriorArtSearch.description = this.searchData.description || null;
    // tslint:disable-next-line: strict-boolean-expressions
    newPriorArtSearch.name = this.searchData.inventor || null;
    // tslint:disable-next-line: strict-boolean-expressions
    newPriorArtSearch.title = this.searchData.title || null;
    // tslint:disable-next-line: strict-boolean-expressions
    newPriorArtSearch.publisher = this.searchData.publisher || null;
    newPriorArtSearch.country = this.searchData.country;
    newPriorArtSearch.countryCode = this.searchData.country;
    newPriorArtSearch.countryName = this.searchData.countryName;
    newPriorArtSearch.publishedDate = null;
    this.details = newPriorArtSearch;
    this.itemName = this.translate.instant('priorart.priorArtTypes.literature');
  }

  ngOnChanges(): void {
    if (!!this.grid) {
      this.grid.search();
    }
  }

  buildGridOptions(): IpxGridOptions {
    const pageSizeSetting = this.localSettings.keys.priorart.search.literaturePageSize;

    return {
      sortable: true,
      selectable: {
        mode: 'single'
      },
      autobind: true,
      detailTemplate: this.dataDetailTemplate,
      read$: (queryParams) => {
        if (this.expandFirstRowOnRefresh) {
          queryParams.sortBy = 'LastModifiedDate';
          queryParams.sortDir = 'Desc';
        }
        this.searchData.queryParameters = queryParams;

        return this.service.getSearchedData$(this.searchData, queryParams).pipe(delay(100), map(data => {
          const inprotechDataSet = _.find(data.result, (t: any) => {
            return t.source === PriorArtSearchType.ExistingPriorArtFinder;
          });

          if (!!inprotechDataSet && inprotechDataSet.matches) {
            _.each(inprotechDataSet.matches.data, (dataitem: any) => {
                dataitem.publishedDate = !!dataitem.publishedDate ? new Date(dataitem.publishedDate) : null;
            });

            return inprotechDataSet.matches;
          }

          return null;
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
      const collapseElement = this.grid.wrapper.wrapper.nativeElement.querySelector('.k-hierarchy-cell .k-minus');
      if (collapseElement) {
        collapseElement.click();
      }
      if (this.dataLiteratureDetailComponent) {
          event.revertAddLiterature = true;
          this.dataLiteratureDetailComponent.revertForm(event);
      }
      this.onRefreshGrid.emit(event);
      this.showAddNewLiterature = false;
    }
  }

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    const columns: Array<GridColumnDefinition> = [
      {
        title: 'priorart.description',
        field: 'description',
        template: false,
        sortable: true,
        width: 400
      },
      {
        title: 'priorart.titleLiterature',
        field: 'title',
        template: false,
        sortable: true,
        width: 400
      },
      {
        title: 'priorart.inventorNameLiterature',
        field: 'name',
        template: false,
        sortable: true,
        width: 400
      },
      {
        title: 'priorart.published',
        field: 'published',
        template: false,
        sortable: true,
        type: 'date',
        defaultColumnTemplate: DefaultColumnTemplateType.date,
        width: 100
      },
      {
        title: 'priorart.publisher',
        field: 'publisher',
        template: false,
        sortable: true,
        width: 200
      },
      {
        title: 'priorart.country',
        field: 'countryName',
        template: false,
        sortable: true,
        width: 200
        },
        {
            title: '',
            field: 'canEdit',
            template: true,
            sortable: false,
            width: 10
        }];
    if (this.enableCiting) {
      columns.push(
        {
          title: '',
          field: 'buttons',
          template: true,
          sortable: false,
          width: 10
        });
    }

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
    const citeData = () => {
      const saveData = { ...new PriorArtSearchResult(), id: dataItem.id, sourceDocumentId: this.searchData.sourceDocumentId };
      this.service.citeInprotechPriorArt$(saveData, this.searchData.caseKey)
        .subscribe(() => {
          dataItem.isCited = true;
          this.successNotificationService.success('priorart.citedMessage');
          if (!!this.dataDetailComponent) {
            this.dataDetailComponent.resetForm();
          }
          this.cdr.detectChanges();
        });
    };

    if (dataItem.hasChanges) {
      const modal = this.notificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.dataDetailComponent.revertForm(null);
          dataItem.hasChanges = false;
          citeData();
          modal.hide();
        });
    } else {
      citeData();
    }
  }

  addLiterature(): void {
      this.showAddNewLiterature = true;
      this.cdr.detectChanges();
      setTimeout(() => {
        document.querySelector('#add-new-literature').scrollIntoView();
      }, 100);
  }

    edit = (dataItem: any): void => {
        PriorartMaintenanceHelper.openMaintenance(dataItem, this.searchData.caseKey);
    };
}
