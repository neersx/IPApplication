import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { StateService } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { PriorArtType } from 'cases/prior-art/priorart-model';
import { PriorArtSearch } from 'cases/prior-art/priorart-search/priorart-search-model';
import { PriorArtService } from 'cases/prior-art/priorart.service';
import { LocalSettings } from 'core/local-settings';
import { takeWhile } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { PriorartMaintenanceHelper } from '../priorart-maintenance-helper';

@Component({
    selector: 'ipx-citations-list',
    templateUrl: './citations-list.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class CitationsListComponent implements OnInit {
    @Input() sourceData: any;
    @Input() priorArtType: PriorArtType;
    @Input() hasDeletePermission: boolean;
    @Input() hasUpdatePermission: boolean;
    @ViewChild('associatedArtGrid', { static: false }) grid: IpxKendoGridComponent;
    get PriorArtTypeEnum(): typeof PriorArtType {
        return PriorArtType;
    }
    gridOptions: any;
    queryParams: GridQueryParameters;
    listCount: Number = 0;
    constructor(private readonly service: PriorArtService,
        private readonly cdRef: ChangeDetectorRef,
        readonly stateService: StateService,
        readonly localSettings: LocalSettings,
        private readonly notificationService: NotificationService,
        private readonly ipxNotificationService: IpxNotificationService) {
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
    }

    buildGridOptions(): IpxGridOptions {
        const pageSizeSetting = this.localSettings.keys.priorart.citationsListPageSize;

        return {
            sortable: true,
            autobind: true,
            pageable: {
                pageSizeSetting,
                pageSizes: [20, 50, 100, 200]
            },
            read$: (queryParams: GridQueryParameters) => {
                this.queryParams = queryParams;

                return this.service.getCitations$({ ...new PriorArtSearch(), ...{ sourceDocumentId: this.sourceData.sourceId, isSourceDocument: this.sourceData.isSourceDocument } }, queryParams);
            },
            columns: this.getColumns(this.sourceData.isSourceDocument),
            onDataBound: (boundData: any) => {

                this.listCount = boundData.length;
                this.cdRef.detectChanges();
            },
            rowMaintenance: {
                canDelete: this.hasDeletePermission,
                canEdit: this.hasUpdatePermission,
                width: '50px',
                deleteTooltip: this.priorArtType === PriorArtType.Source ? 'priorart.maintenance.step2.deleteCitation.priorArtTooltip' : 'priorart.maintenance.step2.deleteCitation.sourceTooltip',
                editTooltip: this.priorArtType === PriorArtType.Source ? 'priorart.maintenance.step2.editCitation.priorArtTooltip' : 'priorart.maintenance.step2.editCitation.sourceTooltip'
            }
        };
    }

    private readonly getColumns = (isSource: boolean): Array<GridColumnDefinition> => {
        if (isSource) {
            return [
                {
                    title: '',
                    field: 'isIpoIssued',
                    template: true,
                    width: 15,
                    sortable: {
                        allowUnsort: true
                    },
                    fixed: true
                },
                {
                    title: 'priorart.reference',
                    field: 'reference',
                    template: true,
                    width: 200
                },
                {
                    title: 'priorart.jurisdiction',
                    field: 'countryName',
                    template: false,
                    width: 200
                },
                {
                    title: 'priorart.kind',
                    field: 'kind',
                    template: false,
                    width: 80
                },
                {
                    title: 'priorart.title',
                    field: 'title',
                    template: false,
                    width: 300
                },
                {
                    title: 'priorart.applicant',
                    field: 'name',
                    template: false
                },
                {
                    title: 'priorart.description',
                    field: 'description',
                    template: false,
                    width: 300
                },
                {
                    title: 'priorart.citation',
                    field: 'citation',
                    template: false
                }];
        }

        return [
            {
                title: 'priorart.source',
                field: 'sourceType',
                template: true,
                width: 100
            },
            {
                title: 'priorart.jurisdiction',
                field: 'issuingJurisdiction',
                template: false,
                width: 100
            },
            {
                title: 'priorart.description',
                field: 'description',
                template: false,
                width: 200
            },
            {
                title: 'priorart.publication',
                field: 'publication',
                template: false,
                width: 100
            },
            {
                title: 'priorart.reportIssued',
                field: 'reportIssued',
                type: 'date',
                defaultColumnTemplate: DefaultColumnTemplateType.date,
                template: false,
                width: 60
            },
            {
                title: 'priorart.reportReceived',
                field: 'reportReceived',
                type: 'date',
                defaultColumnTemplate: DefaultColumnTemplateType.date,
                template: false,
                width: 60
            },
            {
                title: 'priorart.comments',
                field: 'comments',
                template: false,
                width: 100
            }];
    };

    launchSearch = (): void => {
        this.stateService.go('priorArt', {
            caseKey: this.stateService.params.caseKey,
            sourceId: this.stateService.params.sourceId || this.stateService.params.priorartId,
            showCloseButton: true
        });
    };

    deleteCitation = (dataItem: any): void => {
        const notificationRef = this.ipxNotificationService.openConfirmationModal('priorart.maintenance.step2.deleteCitation.title', 'priorart.maintenance.step2.deleteCitation.confirm');
        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => {
                const searchReportId = this.sourceData.isSourceDocument ? Number(this.sourceData.sourceId) : Number(dataItem.id);
                const citedPriorArtId = this.sourceData.isSourceDocument ? Number(dataItem.id) : Number(this.sourceData.sourceId);
                this.service.deleteCitation$(searchReportId, citedPriorArtId)
                    .subscribe((response: any) => {
                        if (response.result) {
                            this.grid.search();
                            this.notificationService.success();
                        }
                    });
            });
    };

    editCitation = (dataItem: any): void => {
        PriorartMaintenanceHelper.openMaintenance(dataItem.dataItem, this.stateService.params.caseKey);
    };
}