import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LinkType, PriorArtType } from 'cases/prior-art/priorart-model';
import { PriorArtService } from 'cases/prior-art/priorart.service';
import { LocalSettings } from 'core/local-settings';
import { race, ReplaySubject } from 'rxjs';
import { map, take, takeUntil } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { AddLinkedCasesComponent } from '../linked-cases/add-linked-cases/add-linked-cases.component';

@Component({
    selector: 'ipx-family-caselist-name',
    templateUrl: './family-caselist-name.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class FamilyCaselistNameComponent implements OnInit, OnDestroy {
    @Input() sourceData: any;
    @Input() priorArtType: PriorArtType;
    @Input() hasDeletePermission: boolean;
    @ViewChild('caseDetailsTemplate', { static: true }) caseDetails: TemplateRef<any>;
    familyGridOptions: any;
    nameGridOptions: any;
    caseDetailsGridOptions: any;
    queryParams: GridQueryParameters;
    isSource: boolean;
    familyGridCount: Number = 0;
    nameGridCount: Number = 0;
    destroy$: ReplaySubject<any> = new ReplaySubject<any>(1);

    constructor(private readonly service: PriorArtService,
        readonly localSettings: LocalSettings,
        readonly notificationService: NotificationService,
        readonly ipxNotificationService: IpxNotificationService,
        readonly translateService: TranslateService,
        readonly modalService: IpxModalService) {
    }
    ngOnDestroy(): void {
        this.destroy$.next(null);
        this.destroy$.complete();
    }

    ngOnInit(): void {
        this.familyGridOptions = this.buildFamilyGridOptions();
        this.nameGridOptions = this.buildNameGridOptions();
        this.isSource = this.sourceData.isSourceDocument;
        this.subscribeToUpdates();
    }

    buildFamilyGridOptions(): IpxGridOptions {
        const pageSizeSetting = this.localSettings.keys.priorart.linkedFamilyCaseListGrid;

        return {
            sortable: true,
            autobind: true,
            detailTemplate: this.caseDetails,
            pageable: {
                pageSizeSetting,
                pageSizes: [5, 10, 20, 50]
            },
            read$: (queryParams: GridQueryParameters) => {
                this.queryParams = queryParams;

                return this.service.getFamilyCaseList$(this.sourceData.sourceId, queryParams);
            },
            onDataBound: (boundData: any) => {
                this.familyGridCount = boundData.data.length;
            },
            columns: this.getFamilyColumns()
        };
    }

    buildNameGridOptions(): IpxGridOptions {
        const pageSizeSetting = this.localSettings.keys.priorart.linkedNameGrid;

        return {
            sortable: true,
            autobind: true,
            pageable: {
                pageSizeSetting,
                pageSizes: [5, 10, 20, 50]
            },
            read$: (queryParams: GridQueryParameters) => {
                this.queryParams = queryParams;

                return this.service.getLinkedNameList$(this.sourceData.sourceId, queryParams);
            },
            onDataBound: (boundData: any) => {
                this.nameGridCount = boundData.data.length;
            },
            columns: this.getNameColumns()
        };
    }

    refreshGrid(): void {
        this.familyGridOptions._search();
        this.nameGridOptions._search();
    }

    countGrids(): Number {
        return +this.familyGridCount + +this.nameGridCount;
    }

    deleteRecord(dataItem: any): void {
        const message = dataItem.nameNo ? 'priorart.maintenance.step4.removeLink.confirm.name' : (dataItem.isFamily ? 'priorart.maintenance.step4.removeLink.confirm.family' : 'priorart.maintenance.step4.removeLink.confirm.caseList');
        const notice = this.sourceData.isSourceDocument ? this.translateService.instant('priorart.maintenance.step4.removeLink.confirm.forSource') : '';
        const notificationRef = this.ipxNotificationService.openConfirmationModal('priorart.maintenance.step4.removeLink.title', message, 'Yes', 'No', null, {forSource: notice});
        race(notificationRef.content.confirmed$.pipe(map(() => true)),
            this.ipxNotificationService.onHide$.pipe(map(() => false)))
            .pipe(take(1))
            .subscribe((confirmed: boolean) => {
                if (!!confirmed) {
                    const linkType = (dataItem.nameNo ? LinkType.Name : (dataItem.isFamily ? LinkType.Family : LinkType.CaseList));
                    this.service.removeAssociation$(linkType, this.sourceData.sourceId, dataItem.id)
                        .pipe(take(1))
                        .subscribe((response: any) => {
                            if (response.isSuccessful) {
                                this.service.hasUpdatedAssociations$.next(true);
                                this.notificationService.success();
                            } else {
                                this.notificationService.alert({});
                            }
                        });

                }
            });
    }

    linkCases = (): void => {
        const addLinkedCasesRef = this.modalService.openModal(AddLinkedCasesComponent, {
            animated: false,
            ignoreBackdropClick: true,
            class: 'modal-lg',
            initialState: { sourceData: this.sourceData, invokedFromCases: false }
        });
        addLinkedCasesRef.content.success$
            .subscribe((response: boolean) => {
                if (response) {
                    this.service.hasUpdatedAssociations$.next(true);
                }
            });
    };

    subscribeToUpdates(): void {
        this.service.hasUpdatedAssociations$.pipe(takeUntil(this.destroy$))
            .subscribe((res: boolean) => {
            if (res) {
                this.refreshGrid();
                this.service.hasUpdatedAssociations$.next(false);
            }

            return;
        });
    }

    private readonly getFamilyColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [
            {
                title: 'priorart.maintenance.step4.familyCaselist.columns.linkedFrom',
                field: 'isFamily',
                template: true,
                width: 500
            },
            {
                title: 'priorart.maintenance.step4.familyCaselist.columns.name',
                field: 'description',
                template: true
            }];

        if (this.hasDeletePermission) {
            columns.unshift({
                title: '',
                field: 'id',
                template: true,
                sortable: false,
                width: 5
            });
        }

        return columns;
    };

    private readonly getNameColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [
            {
                title: 'priorart.maintenance.step4.name.columns.name',
                field: 'linkedViaNames',
                width: 500
            },
            {
                title: 'priorart.maintenance.step4.name.columns.nameType',
                field: 'nameType',
                template: true
            }];
        if (this.hasDeletePermission) {
            columns.unshift({
                title: '',
                field: 'id',
                template: true,
                sortable: false,
                width: 5
            });
        }

        return columns;
    };
}
