import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { StateService } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { PriorArtType } from 'cases/prior-art/priorart-model';
import { PriorArtSearch } from 'cases/prior-art/priorart-search/priorart-search-model';
import { PriorArtService } from 'cases/prior-art/priorart.service';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject, race, ReplaySubject } from 'rxjs';
import { distinctUntilChanged, map, take, takeUntil } from 'rxjs/operators';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { AddLinkedCasesComponent } from './add-linked-cases/add-linked-cases.component';
import { UpdateFirstLinkedComponent } from './update-first-linked-case/update-first-linked.component';
import { UpdatePriorArtStatusComponent } from './update-priorart-status/update-priorart-status.component';

@Component({
    selector: 'ipx-linked-cases',
    templateUrl: './linked-cases.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class LinkedCasesComponent implements OnInit, AfterViewInit, OnDestroy {
    @Input() sourceData: any;
    @Input() priorArtType: PriorArtType;
    bulkActions: Array<IpxBulkActionOptions>;
    @Input() hasDeletePermission: boolean;
    @Input() hasUpdatePermission: boolean;
    @ViewChild('linkedCasesGrid', { static: false }) grid: IpxKendoGridComponent;
    get PriorArtTypeEnum(): typeof PriorArtType {
        return PriorArtType;
    }
    gridOptions: any;
    queryParams: GridQueryParameters;
    listCount: Number = 0;
    _hasRowSelection = new BehaviorSubject<boolean>(false);
    _hasSingleRowSelection = new BehaviorSubject<boolean>(false);
    _canSetAsFirstLinked = new BehaviorSubject<boolean>(false);
    _singleEntrySelected: any;
    _allowSelection: boolean;
    destroy$: ReplaySubject<any> = new ReplaySubject<any>(1);

    constructor(private readonly service: PriorArtService,
        private readonly cdRef: ChangeDetectorRef,
        readonly stateService: StateService,
        readonly localSettings: LocalSettings,
        readonly modalService: IpxModalService,
        readonly notificationService: NotificationService,
        readonly ipxNotificationService: IpxNotificationService) {
    }

    ngOnDestroy(): void {
        this.destroy$.next(null);
        this.destroy$.complete();
    }

    ngOnInit(): void {
        this._allowSelection = this.hasUpdatePermission || this.hasDeletePermission;
        this.initMenuActions();
        this.gridOptions = this.buildGridOptions();
        this.subscribeToUpdates();
    }

    ngAfterViewInit(): void {
        this.subscribeToRowSelection();
    }

    buildGridOptions(): IpxGridOptions {
        const pageSizeSetting = this.localSettings.keys.priorart.linkedCasesPageSize;

        return {
            sortable: true,
            autobind: true,
            filterable: true,
            selectable: this._allowSelection ? {
                mode: 'multiple'
            } : false,
            pageable: {
                pageSizeSetting,
                pageSizes: [20, 50, 100, 200]
            },
            read$: (queryParams: GridQueryParameters) => {
                this.queryParams = queryParams;

                return this.service.getLinkedCases$({ ...new PriorArtSearch(), ...{ sourceDocumentId: this.sourceData.sourceId } }, queryParams);
            },

            filterMetaData$: (column: GridColumnDefinition) => {
                return this.service.runLinkedCasesFilterMetaSearch$(column.field);
            },
            columns: this.getColumns(),
            bulkActions: this._allowSelection ? this.bulkActions : null,
            onDataBound: (boundData: any) => {
                this.listCount = boundData.total;
                this.cdRef.detectChanges();
            },
            selectedRecords: {
                rows: {
                    rowKeyField: 'caseKey',
                    selectedKeys: []
                }
            }
        };
    }

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        return [
            {
                title: '',
                field: 'isCaseFirstLinked',
                width: 32,
                template: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.caseRef',
                field: 'caseReference',
                template: true,
                width: 200,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.officialNo',
                field: 'officialNumber',
                width: 200,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.jurisdiction',
                field: 'jurisdiction',
                width: 80,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.caseStatus',
                field: 'caseStatus',
                width: 100,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.priorArtStatus',
                field: 'priorArtStatus',
                width: 80,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.dateUpdated',
                field: 'dateUpdated',
                width: 80,
                type: 'date',
                defaultColumnTemplate: DefaultColumnTemplateType.date,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.relationship',
                field: 'relationship',
                width: 32,
                defaultColumnTemplate: DefaultColumnTemplateType.selection,
                disabled: true,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.family',
                field: 'family',
                template: true,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.caseList',
                field: 'caseList',
                width: 200,
                filter: true
            },
            {
                title: 'priorart.maintenance.step3.linkedCases.columns.linkedViaNames',
                field: 'linkedViaNames',
                filter: true
            }];
    };

    refreshGrid = () => {
        this.grid.clearSelection();
        this.gridOptions._search();
        this.cdRef.markForCheck();
    };

    linkCases = (): void => {
        const addLinkedCasesRef = this.modalService.openModal(AddLinkedCasesComponent, {
            animated: false,
            ignoreBackdropClick: true,
            class: 'modal-lg',
            initialState: { sourceData: this.sourceData, invokedFromCases: true }
        });
        addLinkedCasesRef.content.success$
            .subscribe((response: boolean) => {
                if (response) {
                    this.service.hasUpdatedAssociations$.next(true);
                }
            }
            );
    };

    initMenuActions(): void {
        if (!this.hasUpdatePermission && !this.hasDeletePermission) {
            this.bulkActions = null;

            return;
        }
        this.bulkActions = [];
        if (this.hasUpdatePermission) {
            this.bulkActions.push(...[{
                ...new IpxBulkActionOptions(),
                id: 'change-first-linked',
                icon: 'cpa-icon cpa-icon-check',
                text: 'bulkactionsmenu.changeFirstLinked',
                enabled$: this._canSetAsFirstLinked.asObservable().pipe(map((result) => result)),
                click: () => this.changeFirstLinked()
            }, {
                ...new IpxBulkActionOptions(),
                id: 'change-status',
                icon: 'cpa-icon cpa-icon-edit',
                text: 'bulkactionsmenu.changeStatus',
                enabled$: this._hasRowSelection.asObservable().pipe(map((result) => result)),
                click: () => this.changeStatus()
            }]);
        }
        if (this.hasDeletePermission) {
            this.bulkActions.push({
                ...new IpxBulkActionOptions(),
                id: 'remove-linked-case',
                icon: 'cpa-icon cpa-icon-trash',
                text: 'priorart.maintenance.step3.linkedCases.removeLink.tooltip',
                enabled$: this._hasRowSelection.asObservable().pipe(map((result) => result)),
                click: () => this.removeLinkedCases()
            });
        }
    }

    changeStatus(): void {
        const selectionDetails = this.getSelectionDetails();
        const selectedCaseKeys = selectionDetails.isSelectAll ? [] : selectionDetails.selectedCaseKeys;
        const exceptCaseKeys = selectionDetails.isSelectAll ? selectionDetails.exceptCaseKeys : [];
        const changeStatusModal = this.modalService.openModal(UpdatePriorArtStatusComponent, {ignoreBackdropClick: true, class: 'modal-lg', initialState: { caseKeys: selectedCaseKeys, sourceDocumentId: this.sourceData.sourceId, isSelectAll: selectionDetails.isSelectAll, exceptCaseKeys, queryParams: this.queryParams } });
        changeStatusModal.content.success$.pipe(take(1)).subscribe((successful: boolean) => {
            this.notificationService.success();
            this.refreshGrid();
        });
    }

    getSelectionDetails = (): any => {
        const isSelectAll = this.grid.getRowSelectionParams().isAllPageSelect;
        let selectedCaseKeys = this.grid.getRowSelectionParams().rowSelection;
        if (!selectedCaseKeys.length) {
            selectedCaseKeys = this.grid.getSelectedItems('caseKey');
        }
        const exceptCaseKeys = _.pluck(this.grid.getRowSelectionParams().allDeSelectedItems, 'caseKey');

        return { isSelectAll, selectedCaseKeys, exceptCaseKeys };
    };

    modalRef: any;
    changeFirstLinked(): void {
        const selectionDetails = this.getSelectionDetails();
        const selectedCaseKeys = selectionDetails.selectedCaseKeys;
        this.modalRef = this.modalService.openModal(UpdateFirstLinkedComponent, { initialState: { caseKeys: selectedCaseKeys, sourceDocumentId: this.sourceData.sourceId }, ignoreBackdropClick: true, class: 'modal-lg' });
        this.modalRef.content.confirmed$.subscribe((response: any) => {
            if (response) {
                this.service.updateFirstLinkedCaseViewData$({ caseKeys: selectedCaseKeys, sourceDocumentId: this.sourceData.sourceId, keepCurrent: response.keepCurrent }).subscribe(rsp => {
                    this.refreshGrid();
                    this.modalRef.hide();
                    this.notificationService.success();
                    this._hasRowSelection.next(false);
                });
            }
        });
    }

    subscribeToRowSelection = () => {
        this.grid.rowSelectionChanged.subscribe((event) => {
            this._hasRowSelection.next(event.rowSelection.length > 0);
            this._singleEntrySelected = event.rowSelection.length !== 1 ? null : event.rowSelection[0];
            this._canSetAsFirstLinked.next(event.rowSelection.length === 1 && !event.rowSelection[0].isCaseFirstLinked);
            this.cdRef.detectChanges();
        });
        this.grid.getRowSelectionParams().singleRowSelected$.subscribe((status) => {
            this._hasSingleRowSelection.next(status);
        });
    };

    removeLinkedCases = (): void => {
        const selectionDetails = this.getSelectionDetails();
        const selectedCaseKeys = selectionDetails.isSelectAll ? [] : selectionDetails.selectedCaseKeys;
        const exceptCaseKeys = selectionDetails.isSelectAll ? selectionDetails.exceptCaseKeys : [];
        const notificationRef = this.ipxNotificationService.openConfirmationModal('priorart.maintenance.step3.linkedCases.removeLink.title', 'priorart.maintenance.step3.linkedCases.removeLink.message', 'Yes', 'No');
        race(notificationRef.content.confirmed$.pipe(map(() => true)),
            this.ipxNotificationService.onHide$.pipe(map(() => false)))
            .pipe(take(1))
            .subscribe((confirmed: boolean) => {
                if (!!confirmed) {
                    this.service.removeLinkedCases$({ sourceDocumentId: this.sourceData.sourceId, isSelectAll: selectionDetails.isSelectAll, caseKeys: selectedCaseKeys, exceptCaseKeys }, this.queryParams)
                        .pipe(take(1))
                        .subscribe((response: any) => {
                            if (!!response.isSuccessful) {
                                this.notificationService.success();
                                this.service.hasUpdatedAssociations$.next(true);
                            }
                        });
                }
            });
    };

    subscribeToUpdates(): void {
        this.service.hasUpdatedAssociations$
            .pipe(takeUntil(this.destroy$))
            .subscribe((res: boolean) => {
                if (res) {
                    this.refreshGrid();
                    this.service.hasUpdatedAssociations$.next(false);
                }

            return;
        });
    }
}
