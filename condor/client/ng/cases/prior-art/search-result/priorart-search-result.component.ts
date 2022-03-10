import { ChangeDetectionStrategy, ChangeDetectorRef,  Component, EventEmitter, Input, OnChanges, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { merge, of } from 'rxjs';
import { delay, map, take } from 'rxjs/operators';
import { GridHelper } from 'shared/component/grid/ipx-grid-helper';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { PriorArtDetailsComponent } from '../priorart-details/priorart-details.component';
import { PriorartMaintenanceHelper } from '../priorart-maintenance/priorart-maintenance-helper';
import { PriorArtSaveModel } from '../priorart-model';
import { PriorArtOrigin, PriorArtSearch, PriorArtSearchResult, PriorArtSearchType } from '../priorart-search/priorart-search-model';
import { PriorArtService } from '../priorart.service';

@Component({
    selector: 'ipx-priorart-search-result',
    templateUrl: './priorart-search-result.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PriorartSearchResultComponent implements OnInit, OnChanges {
  @ViewChild('dataDetailTemplate', { static: true }) dataDetailTemplate: TemplateRef<any>;
  @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
  @ViewChild('dataDetailComponent', { static: false }) dataDetailComponent: PriorArtDetailsComponent;
  @Input() data: Array<PriorArtSearchResult>;
  @Input() searchData: PriorArtSearch;
  @Input() hidePriorArtStatus: boolean | false;
  @Input() hasIpd1Error: boolean | false;
  @Input() translationsList: any = {};
  @Output() readonly onRefreshGrid = new EventEmitter();
  gridOptions: IpxGridOptions;
  originIpOne: any;
  originInprotech: any;
  expandFirstRowOnRefresh = false;
  constructor(private readonly service: PriorArtService, private readonly notificationService: IpxNotificationService, private readonly successNotificationService: NotificationService, private readonly cdr: ChangeDetectorRef, private readonly localSettings: LocalSettings, private readonly dateHelper: DateHelper) {}

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
        return {
            selectable: {
                mode: 'single'
            },
            autobind: true,
            read$: () => {
                return of({
                    data: this.data,
                    pagination: { total: this.data.length }
                }).pipe(delay(100));
            },
            columns: this.getColumns(),
            detailTemplate: this.dataDetailTemplate,
            gridMessages: {
                noResultsFound: this.hasIpd1Error ? 'priorart.noResultsInprotechErr' : 'priorart.noResultsErr',
                performSearch: 'priorart.noResultsErr'
            },
            persistSelection: false,
            reorderable: true,
            navigable: true,
            onDataBound: () => {
                const settings = this.localSettings.keys.priorart.search.caseResultSize;
                this.pageChanged({ skip: 0, take: settings.getLocal });
                if (this.expandFirstRowOnRefresh) {
                    this.grid.collapseAll();
                    this.grid.navigateByIndex(0);
                    this.grid.wrapper.expandRow(0);
                    this.expandFirstRowOnRefresh = false;
                }
            },
            customRowClass: (context) => {
                if (context.dataItem.isSaved) { return 'saved'; }

                return '';
            },
            pageable: {
                pageSizeSetting: this.localSettings.keys.priorart.search.caseResultSize,
                pageSizes: [10, 20]
            },
            manualOperations: true,
            sortable: true
        };
    }

    onSaveData(event): void {
      if (event.success) {
        this.successNotificationService.success();
      }
    }

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const columns = [
          {
            title: 'priorart.reference',
            field: 'reference',
            template: true,
            sortable: true,
            width: 200
          },
          {
            title: 'priorart.jurisdiction',
            field: 'countryName',
            template: false,
            sortable: true,
            width: 200
          },
          {
            title: 'priorart.kind',
            field: 'kind',
            template: false,
            sortable: true,
            width: 80
          },
          {
            title: 'priorart.origin',
            field: 'origin',
            template: false,
            sortable: true,
            width: 150
          },
          {
            title: 'priorart.title',
            field: 'title',
            template: false,
            sortable: true
          }];
          if (!this.hidePriorArtStatus) {
            columns.push(
              {
                title: 'priorart.status',
                field: 'priorArtStatus',
                template: false,
                sortable: true,
                width: 500
              });
          }
          columns.push(
              {
                  title: '',
                  field: 'canEdit',
                  template: true,
                  sortable: true,
                  width: 25
              },
            {
              title: '',
              field: 'buttons',
              template: true,
              sortable: false,
              width: 25
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
      const citeData = () => {
        const saveData: PriorArtSearchResult = { ...dataItem, sourceDocumentId: this.searchData.sourceDocumentId };
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
            });
            modal.hide();
      } else {
        citeData();
      }
   }

    _toLocalDate(dateTime: Date): Date {
        if (dateTime instanceof Date) {
            return new Date(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate(), 0, 0, 0);
        }

        return null;
    }

    import(dataItem: any): void {
      const persist = () => {
          // tslint:disable-next-line:no-shadowed-variable
          const result = {
              id: dataItem.id,
              reference: dataItem.reference,
              citation: dataItem.citation,
              title: dataItem.title,
              name: dataItem.name,
              kind: dataItem.kind,
              abstract: dataItem.abstract,
              applicationDate: !!this.dataDetailComponent ? this.dateHelper.toLocal(this._toLocalDate(this.dataDetailComponent.applicationDate.value)) : null,
              publishedDate: !!this.dataDetailComponent ? this.dateHelper.toLocal(this._toLocalDate(this.dataDetailComponent.publishedDate.value)) : null,
              grantedDate: !!this.dataDetailComponent ? this.dateHelper.toLocal(this._toLocalDate(this.dataDetailComponent.grantedDate.value)) : null,
              priorityDate: !!this.dataDetailComponent ? this.dateHelper.toLocal(this._toLocalDate(this.dataDetailComponent.priorityDate.value)) : null,
              ptoCitedDate: !!this.dataDetailComponent ? this.dateHelper.toLocal(this._toLocalDate(this.dataDetailComponent.ptoCitedDate.value)) : null,
              referenceLink: dataItem.referenceLink,
              isComplete: dataItem.isComplete,
              countryName: dataItem.countryName,
              countryCode: dataItem.countryCode,
              origin: dataItem.origin,
              type: dataItem.type,
              officialNumber: dataItem.officialNumber,
              caseStatus: dataItem.caseStatus,
              comments: dataItem.comments,
              translation: dataItem.translation,
              refDocumentParts: dataItem.refDocumentParts,
              description: dataItem.description
          };

          const saveData: PriorArtSaveModel = {
              evidence: result,
              country: dataItem.countryCode,
              officialNumber: dataItem.officialNumber,
              sourceDocumentId: this.searchData.sourceDocumentId,
              caseKey: this.searchData.caseKey,
              source: PriorArtSearchType.IpOneDataDocumentFinder
          };
          this.service.importIPOne$(saveData)
              .subscribe(() => {
                    dataItem.imported = true;
                    if (this.searchData.sourceDocumentId || this.searchData.caseKey) {
                      this.successNotificationService.success('priorart.importedAndCitedMessage');
                    } else {
                      this.successNotificationService.success('priorart.importedMessage');
                    }
                    if (!!this.dataDetailComponent) {
                      this.dataDetailComponent.resetForm();
                    }
                    const importStatus = { success: true, importedRef: dataItem.reference };
                    this.onRefreshGrid.emit(importStatus);
                    dataItem.hasChanges = false;
                    this.cdr.detectChanges();
              });
      };
      this.service.existingPriorArt$(dataItem.countryCode, dataItem.reference, dataItem.kind)
          .subscribe((response: any) => {
              if (response.result) {
                  const messageParams = {
                      jurisidction: dataItem.countryName,
                      officialNumber: dataItem.reference,
                      kindCode: !!dataItem.kindCode ? ', ' + dataItem.kindCode : ''
                  };
                  const modal = this.notificationService.openConfirmationModal('priorart.confirmImport', 'priorart.existingPriorArt', 'Proceed', 'Cancel', null, messageParams);
                  modal.content.confirmed$.pipe(take(1)).subscribe(() => {
                      persist();
                  });
              } else {
                  persist();
              }
          });
    }

    edit = (dataItem: any): void => {
        PriorartMaintenanceHelper.openMaintenance(dataItem, this.searchData.caseKey);
    };

    pageChanged(event: {skip: number, take: number}): void {
        GridHelper.manualPageChange(this.grid, this.data, event.skip, event.take);
    }
}