import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { of, ReplaySubject } from 'rxjs';
import { delay, take, takeUntil } from 'rxjs/operators';
import { GridHelper } from 'shared/component/grid/ipx-grid-helper';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { PriorArtDetailsComponent } from '../priorart-details/priorart-details.component';
import { PriorArtSaveModel } from '../priorart-model';
import { PriorArtSearch, PriorArtSearchResult, PriorArtSearchType } from '../priorart-search/priorart-search-model';
import { PriorArtService } from '../priorart.service';

@Component({
    selector: 'ipx-priorart-inprotech-cases-result',
    templateUrl: './priorart-inprotech-cases-result.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PriorartInprotechCasesResultComponent implements OnInit {
  @ViewChild('caseDataDetailTemplate', { static: true }) caseDataDetailTemplate: TemplateRef<any>;
  @ViewChild('caseDataDetailComponent', { static: false }) caseDataDetailComponent: PriorArtDetailsComponent;
  @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
  @Input() data: Array<PriorArtSearchResult>;
  @Input() searchData: PriorArtSearch;
  @Input() translationsList: any = {};
  @Output() readonly onRefreshGrid = new EventEmitter();
  destroy: ReplaySubject<any> = new ReplaySubject<any>(1);
  gridOptions: IpxGridOptions;

    constructor(private readonly service: PriorArtService, private readonly notificationService: IpxNotificationService, private readonly successNotificationService: NotificationService, private readonly cdr: ChangeDetectorRef, private readonly localSettings: LocalSettings) {}

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
    }

    buildGridOptions(): IpxGridOptions {
        return {
            selectable: {
                mode: 'single'
            },
            sortable: false,
            autobind: true,
            detailTemplate: this.caseDataDetailTemplate,
            read$: () => {
              return of({
                  data: this.data,
                  pagination: {total: this.data.length}
              }).pipe(delay(100));
            },
            onDataBound: () => {
                const settings = this.localSettings.keys.priorart.search.caseResultSize;
                this.pageChanged({skip: 0, take: settings.getLocal});
            },
            columns: this.getColumns(),
            persistSelection: false,
            reorderable: true,
            navigable: false,
            pageable: {
              pageSizeSetting: this.localSettings.keys.priorart.search.caseResultSize,
              pageSizes: [10, 20]
            },
            manualOperations: true
        };
    }

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const columns = [
            {
              title: 'priorart.inprotechCases.caseReference',
              field: 'reference',
              template: true,
              width: 200
            },
            {
              title: 'priorart.inprotechCases.officialNumber',
              field: 'officialNumber',
              template: false,
              width: 200
            },
            {
              title: 'priorart.inprotechCases.jurisdiction',
              field: 'countryName',
              template: false,
              width: 230
            },
            {
              title: 'priorart.inprotechCases.title',
              field: 'title',
              template: false
            },
            {
              title: 'priorart.inprotechCases.caseStatus',
              field: 'caseStatus',
              template: false,
              width: 500
            },
            {
              title: '',
              field: 'buttons',
              template: true,
              width: 25,
              sortable: false
            }
        ];

        return columns;
    };

    onCollapse(event: any): void {
        if (event.dataItem.hasChanges) {
            event.prevented = true;
            const modal = this.notificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                  this.caseDataDetailComponent.revertForm(event);
                  event.dataItem.hasChanges = false;
                  const collapseElement = this.grid.wrapper.wrapper.nativeElement.querySelector('.k-hierarchy-cell .k-minus');
                  if (collapseElement) {
                    collapseElement.click();
                  }
                });
          }
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
                applicationDate: !!this.caseDataDetailComponent ? this.service.formatDate(this.caseDataDetailComponent.applicationDate.value) : null,
                publishedDate: !!this.caseDataDetailComponent ? this.service.formatDate(this.caseDataDetailComponent.publishedDate.value) : null,
                grantedDate: !!this.caseDataDetailComponent ? this.service.formatDate(this.caseDataDetailComponent.grantedDate.value) : null,
                priorityDate: !!this.caseDataDetailComponent ? this.service.formatDate(this.caseDataDetailComponent.priorityDate.value) : null,
                ptoCitedDate: !!this.caseDataDetailComponent ? this.service.formatDate(this.caseDataDetailComponent.ptoCitedDate.value) : null,
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
            this.service.importCase$(saveData)
                .pipe(take(1), takeUntil(this.destroy))
                .subscribe(() => {
                      dataItem.imported = true;
                      if (this.searchData.sourceDocumentId || this.searchData.caseKey) {
                        this.successNotificationService.success('priorart.importedAndCitedMessage');
                      } else {
                        this.successNotificationService.success('priorart.importedMessage');
                      }
                      if (!!this.caseDataDetailComponent) {
                        this.caseDataDetailComponent.resetForm();
                      }
                      dataItem.hasChanges = false;
                      const importStatus = { success: true, importedRef: null };
                      this.onRefreshGrid.emit(importStatus);
                      this.cdr.detectChanges();
                });
        };
        this.service.existingPriorArt$(dataItem.countryCode, dataItem.officialNumber, dataItem.kind)
            .pipe(take(1), takeUntil(this.destroy))
            .subscribe((response: any) => {
                if (response.result) {
                    const messageParams = {
                        jurisidction: dataItem.countryName,
                        officialNumber: dataItem.officialNumber,
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

    pageChanged(event: { skip: number, take: number }): void {
        GridHelper.manualPageChange(this.grid, this.data, event.skip, event.take);
   }
}