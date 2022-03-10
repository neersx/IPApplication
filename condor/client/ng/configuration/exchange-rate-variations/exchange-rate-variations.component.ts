import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { criteriaPurposeCode, SearchService } from 'configuration/rules/screen-designer/case/search/search.service';
import { LocalSettings } from 'core/local-settings';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { BehaviorSubject } from 'rxjs';
import { takeWhile } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxTypeaheadComponent } from 'shared/component/typeahead/ipx-typeahead';
import * as _ from 'underscore';
import { ExchangeRateVariationFormData, ExchangeRateVariationPermissions } from './exchange-rate-variations.model';
import { ExchangeRateVariationService } from './exchange-rate-variations.service';
import { MaintainExchangerateVarComponent } from './maintain-exchangerate-var/maintain-exchangerate-var.component';

@Component({
    selector: 'currencies',
    templateUrl: './exchange-rate-variations.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ],
    providers: [
        CaseValidCombinationService
    ]
})

export class ExchangeRateVariationComponent implements OnInit {
    @Input() viewData: ExchangeRateVariationPermissions;
    gridOptions: IpxGridOptions;
    showSearchBar = true;
    formData: ExchangeRateVariationFormData;
    picklistValidCombination: any;
    extendPicklistQuery: any;
    addedRecordId: number;
    _resultsGrid: any;
    actions: Array<IpxBulkActionOptions>;
    isCaseCategoryDisabled = new BehaviorSubject(true);
    cannotDeleteIds: Array<string> = [];
    @ViewChild('exchangeRateVariationGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }
    @ViewChild('casePicklist', { static: true }) casePicklist: IpxTypeaheadComponent;
    @ViewChild('searchForm', { static: true }) form: NgForm;

    constructor(private readonly service: ExchangeRateVariationService, readonly localSettings: LocalSettings,
        public cvs: CaseValidCombinationService, public searchService: SearchService,
        private readonly cdRef: ChangeDetectorRef, private readonly ipxNotificationService: IpxNotificationService,
        private readonly modalService: IpxModalService,
        private readonly notificationService: NotificationService, private readonly translate: TranslateService) { }

    ngOnInit(): void {
        this.actions = this.initializeMenuActions();
        this.formData = new ExchangeRateVariationFormData();
        this.actions = this.initializeMenuActions();
        this.gridOptions = this.buildGridOptions();
        const params = this.localSettings.keys.exchangeRateVariation.data.getSession;
        if (params) {
            this.formData.currency = params.currency ? { id: params.currency, code: params.currency, description: params.currencyDesc } : null;
            this.formData.exchangeRateSchedule = params.exchangeRateSchedule ? { id: params.exchangeRateSchedule, description: params.exchangeRateScheduleDesc } : null;
            this.localSettings.keys.exchangeRateVariation.data.setSession(null);
        }
        this.resetFormData();
    }

    private initializeMenuActions(): Array<IpxBulkActionOptions> {
        const menuItems: Array<IpxBulkActionOptions> = [];

        if (this.viewData.canEdit) {
            menuItems.push(
                {
                    ...new IpxBulkActionOptions(),
                    id: 'edit',
                    icon: 'cpa-icon cpa-icon-edit',
                    text: 'exchangeRateVariation.maintenance.editOnly',
                    enabled: false,
                    click: this.editExchangeRateVariation
                }
            );
        }
        if (this.viewData.canDelete) {
            menuItems.push({
                ...new IpxBulkActionOptions(),
                id: 'delete',
                icon: 'cpa-icon cpa-icon-trash',
                text: 'office.delete',
                enabled: false,
                click: this.deleteConfirmation
            });
        }

        return menuItems;
    }

    private readonly subscribeRowSelectionChange = () => {
        this._resultsGrid.rowSelectionChanged.subscribe((event) => {
            const edit = this.actions.find(x => x.id === 'edit');
            if (edit) {
                edit.enabled = event.rowSelection.length === 1;
            }

            const bulkDelete = this.actions.find(x => x.id === 'delete');
            if (bulkDelete) {
                bulkDelete.enabled = event.rowSelection.length > 0;
            }
        });
    };

    resetFormData(): void {
        this.cvs.initFormData(this.formData);
        this.isCaseCategoryDisabled.next(true);
        this.picklistValidCombination = this.cvs.validCombinationDescriptionsMap;
        this.extendPicklistQuery = this.cvs.extendValidCombinationPickList;
        this.cdRef.markForCheck();
    }

    verifyCaseCategoryStatus = () => {
        this.isCaseCategoryDisabled.next(this.cvs.isCaseCategoryDisabled());
    };

    useCaseChanged = ($event): void => {
        if (!$event) {
            this.formData.case = null;
        }
    };

    onCriteriaChange = _.debounce(() => {
        this.searchService.validateCaseCharacteristics$(this.form, criteriaPurposeCode.ScreenDesignerCases).then(() => {
            this.verifyCaseCategoryStatus();
        });
    }, 100);

    onCaseChange = (selectedCase): void => {
        if (selectedCase && selectedCase.key) {
            this.searchService.getCaseCharacteristics$(selectedCase.key, criteriaPurposeCode.ScreenDesignerCases).subscribe((caseCharacteristics) => {
                this.formData.jurisdiction = caseCharacteristics.jurisdiction;
                this.formData.caseCategory = caseCharacteristics.caseCategory;
                this.formData.caseType = caseCharacteristics.caseType;
                this.formData.propertyType = caseCharacteristics.propertyType;
                this.formData.subType = caseCharacteristics.subType;
                this.verifyCaseCategoryStatus();
                this.onCriteriaChange();
                this.cdRef.markForCheck();
            });
        }
    };

    search(): void {
        this._resultsGrid.clearSelection();
        this.gridOptions._search();
    }

    clear(): void {
        this.formData = new ExchangeRateVariationFormData();
        this._resultsGrid.clearSelection();
        this.gridOptions._search();
    }

    editExchangeRateVariation = (resultGrid: IpxKendoGridComponent) => {
        const selectedRowKey = resultGrid.getRowSelectionParams().rowSelection[0];
        this.onRowAddedOrEdited(selectedRowKey, 'E');
    };

    deleteConfirmation = (resultGrid: IpxKendoGridComponent): void => {
        const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null);
        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => {
                const rowSelectionParams = resultGrid.getRowSelectionParams();
                let allKeys = [];
                if (rowSelectionParams.isAllPageSelect) {
                    const dataRows = Array.isArray(this._resultsGrid.wrapper.data) ? this._resultsGrid.wrapper.data
                        : (this._resultsGrid.wrapper.data).data;
                    allKeys = _.pluck(dataRows, 'id');
                } else {
                    allKeys = _.map(resultGrid.getRowSelectionParams().allSelectedItems, 'id');
                }
                if (allKeys.length > 0) {
                    this.delete(allKeys);
                }
            });
    };

    delete = (allKeys: Array<number>): void => {
        this.service.deleteExchangeRateVariations(allKeys).subscribe((response: any) => {
            if (response.hasError) {
                const allInUse = allKeys.length === response.inUseIds.length;
                const message = allInUse ? this.translate.instant('modal.alert.alreadyInUse')
                    : this.translate.instant('modal.alert.partialComplete') + '<br/>' + this.translate.instant('modal.alert.alreadyInUse');
                const title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';
                this.notificationService.alert({ title, message });
                this.cannotDeleteIds = response.inUseIds;
            } else {
                this.cannotDeleteIds = null;
                this.notificationService.success();
            }
            this._resultsGrid.clearSelection();
            this.gridOptions._search();
        });
    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            sortable: true,
            reorderable: false,
            pageable: {
                pageSizes: [5, 10, 20, 50],
                pageSizeSetting: this.localSettings.keys.currencies.pageSize
            },
            rowMaintenance: {
                rowEditKeyField: 'id'
            },
            bulkActions: (this.viewData.canEdit || this.viewData.canDelete) ? this.actions : null,
            selectable: (this.viewData.canEdit || this.viewData.canDelete) ? {
                mode: 'multiple'
            } : false,
            selectedRecords: {
                rows: {
                    rowKeyField: 'id',
                    selectedKeys: []
                }
            },
            showGridMessagesUsingInlineAlert: false,
            read$: (queryParams) => {
                const searchFilter = this.formData.getServerReady();

                return this.service.getExchangeRateVariations(searchFilter, queryParams);
            },
            customRowClass: (context) => {
                let returnValue = '';

                if (context.dataItem && context.dataItem.id === this.addedRecordId) {
                    returnValue += 'saved k-state-selected selected';
                }

                if (context.dataItem && this.cannotDeleteIds && this.cannotDeleteIds.length > 0 && this.cannotDeleteIds.indexOf(context.dataItem.id) !== -1) {
                    returnValue += 'error';
                }

                return returnValue;
            },
            enableGridAdd: this.viewData.canAdd,
            columns: this.getColumns()
        };
    }

    onRowAddedOrEdited(data: any, state: string): void {
        const modal = this.modalService.openModal(MaintainExchangerateVarComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                id: data,
                isAdding: state === rowStatus.Adding,
                currencyCodeValue: this.formData ? this.formData.currency : null,
                exchangeRateScheduleCodeValue: this.formData ? this.formData.exchangeRateSchedule : null
            }
        });
        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event);
            }
        );

        modal.content.addedRecordId$.subscribe(
            (event: any) => {
                this.addedRecordId = event;
            }
        );
    }

    onCloseModal(event): void {
        if (event) {
            this.notificationService.success();
            this.gridOptions._search();
        }
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'exchangeRateVariation.columns.currency',
            field: 'currency',
            sortable: true,
            template: true
        }, {
            title: 'exchangeRateVariation.columns.exchangeRateSchedule',
            field: 'exchangeRateSchedule',
            sortable: true,
            template: true
        }, {
            title: 'exchangeRateVariation.columns.buyRate',
            field: 'buyRate',
            sortable: false,
            template: true
        }, {
            title: 'exchangeRateVariation.columns.sellRate',
            field: 'sellRate',
            sortable: false,
            template: true
        }, {
            title: 'exchangeRateVariation.columns.buyFactor',
            field: 'buyFactor',
            sortable: false,
            template: true
        }, {
            title: 'exchangeRateVariation.columns.sellFactor',
            field: 'sellFactor',
            sortable: false,
            template: true
        }, {
            title: 'exchangeRateVariation.columns.caseType',
            field: 'caseType',
            sortable: true
        }, {
            title: 'exchangeRateVariation.columns.jurisdiction',
            field: 'country',
            sortable: true
        }, {
            title: 'exchangeRateVariation.columns.propertyType',
            field: 'propertyType',
            sortable: true
        }, {
            title: 'exchangeRateVariation.columns.caseCategory',
            field: 'caseCategory',
            sortable: true
        }, {
            title: 'exchangeRateVariation.columns.subType',
            field: 'subType',
            sortable: true
        }, {
            title: 'exchangeRateVariation.columns.effectiveDate',
            field: 'effectiveDate',
            sortable: true,
            template: true
        }];

        return columns;
    };

}