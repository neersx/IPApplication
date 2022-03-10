import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { CommonUtilityService } from 'core/common.utility.service';
import { FeatureDetection } from 'core/feature-detection';
import { LocalSettings } from 'core/local-settings';
import { StoreResolvedItemsService } from 'core/storeresolveditems.service';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { WindowRef } from 'core/window-ref';
import { CaseSearchService } from 'search/case/case-search.service';
import { BulkPolicingRequestComponent } from 'search/case/results/bulk-policing-request/bulk-policing-request.component';
import { ExportContentType } from 'search/results/export.content.model';
import { CaseSerachResultFilterService } from 'search/results/search-results.filter.service';
import { TabData } from 'search/task-planner/task-planner.data';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { WipOverviewProvider } from 'search/wip-overview/wip-overview.provider';
import { WipOverviewService } from 'search/wip-overview/wip-overview.service';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import * as _ from 'underscore';
import { PriorArtSearchPermissions, Program } from '../results/search-results.data';
import { CaseSearchPermissions, NameSearchPermissions, WipOverviewSearchPermissions } from './../results/search-results.data';
import { CaseListModalService } from './case-list-modal.service';
import { SearchTypeBillingWorksheetProvider } from './search-type-billing-worksheet.provider';
import { queryContextKeyEnum, SearchTypeConfig, SearchTypeConfigProvider } from './search-type-config.provider';
import { SearchTypeMenuProviderService } from './search-type-menu-provider.service';
import { SearchTypeTaskPlannerProvider } from './search-type-task-planner.provider';

@Injectable()
export class SearchTypeActionMenuProvider {

    permissions: any;
    private config: any;
    searchConfiguration: SearchTypeConfig;
    viewData: any;
    selectedCaseIds: any;
    filter: any;
    queryContextKey: number;
    modalRef: any;
    isReleaseGreaterThan14: boolean;
    isHosted: boolean;
    constructor(
        private readonly localSettings: LocalSettings,
        private readonly stateService: StateService,
        private readonly caseService: CaseSearchService,
        private readonly windowParentMessagingService: WindowParentMessagingService,
        private readonly storeResolvedItemsService: StoreResolvedItemsService,
        private readonly windowRef: WindowRef,
        private readonly commonUtilityService: CommonUtilityService,
        private readonly notificationService: NotificationService,
        private readonly caseSerachResultFilterService: CaseSerachResultFilterService,
        private readonly searchTypeMenuProviderService: SearchTypeMenuProviderService,
        readonly translate: TranslateService,
        private readonly billingWorksheetProvider: SearchTypeBillingWorksheetProvider,
        private readonly modalService: IpxModalService,
        private readonly featureDetection: FeatureDetection,
        private readonly caselistModalSevice: CaseListModalService,
        private readonly taskPlannerProvider: SearchTypeTaskPlannerProvider,
        private readonly wipOverviewProvider: WipOverviewProvider
    ) {
    }

    initializeContext = (permissions: any, queryContextKey: number, exportContentTypeMapper: Array<ExportContentType>, isHosted: boolean): void => {
        this.queryContextKey = queryContextKey;
        this.isHosted = isHosted;
        this.billingWorksheetProvider.initializeContext(permissions, queryContextKey, exportContentTypeMapper);
        this.searchTypeMenuProviderService.baseApiRoute = SearchTypeConfigProvider.getConfigurationConstants(+queryContextKey).baseApiRoute;
        if (permissions) {
            switch (queryContextKey) {
                case queryContextKeyEnum.caseSearch:
                case queryContextKeyEnum.caseSearchExternal:
                    this.permissions = permissions as CaseSearchPermissions;
                    break;
                case queryContextKeyEnum.nameSearch:
                case queryContextKeyEnum.nameSearchExternal:
                    this.permissions = permissions as NameSearchPermissions;
                    break;
                case queryContextKeyEnum.priorArtSearch:
                    this.permissions = permissions as PriorArtSearchPermissions;
                    break;
                case queryContextKeyEnum.wipOverview:
                    this.permissions = permissions as WipOverviewSearchPermissions;
                    break;
                default:
                    break;
            }
        }
        this.featureDetection.hasSpecificRelease$(14).subscribe((response) => {
            this.isReleaseGreaterThan14 = response;
        });
    };

    getConfigurationActionMenuItems = (queryContextKey: number, viewData: any, isHosted: boolean): Array<IpxBulkActionOptions> => {
        const menuItems = [];
        this.config = SearchTypeConfigProvider.getConfigurationConstants(queryContextKey);
        this.viewData = viewData;
        this.viewData.queryContextKey = queryContextKey;

        switch (queryContextKey) {
            case queryContextKeyEnum.nameSearch:
            case queryContextKeyEnum.nameSearchExternal:
                if (viewData.programs.length > 1) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'open-with-program',
                        icon: 'cpa-icon cpa-icon-share-square-o',
                        text: 'bulkactionsmenu.OpenWith',
                        enabled: 'single-selection',
                        items: viewData.programs.map((program: Program) => {
                            return {
                                id: program.id,
                                text: program.name,
                                enabled: true,
                                click: (resultGrid: IpxKendoGridComponent): any => {
                                    if (resultGrid.hasItemsSelected()) {
                                        const nameId = resultGrid.getSelectedItems(this.config.rowKeyField)[0];
                                        const rowKey = resultGrid.getSelectedItems('rowKey')[0];
                                        if (isHosted) {
                                            this.windowParentMessagingService.postNavigationMessage({ args: ['NameDetails', nameId, rowKey, program.id] });
                                        } else {
                                            const params = {
                                                id: nameId,
                                                rowKey,
                                                programId: program.id
                                            };
                                            this.stateService.go('nameview', params);
                                        }
                                    }
                                }
                            };
                        })
                    });
                }
                break;
            case queryContextKeyEnum.caseSearch:
            case queryContextKeyEnum.caseSearchExternal:
                if (this.permissions.canMaintainCaseList && !isHosted) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'add-to-caselist',
                        icon: 'cpa-icon cpa-icon-file-text-o',
                        text: 'bulkactionsmenu.addToCaselist',
                        enabled: false,
                        click: this.addToCaselist
                    });
                }
                if (this.permissions.canMaintainGlobalNameChange && isHosted) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'global-name-change',
                        icon: 'cpa-icon cpa-icon-user-circle',
                        text: 'bulkactionsmenu.GlobalNameChange',
                        enabled: false,
                        click: this.globalNameChange
                    });
                }
                if (this.permissions.canMaintainCase) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'case-bulk-update',
                        icon: 'cpa-icon cpa-icon-pencil-square-o',
                        text: 'bulkactionsmenu.BulkUpdate',
                        enabled: false,
                        click: this.bulkUpdate
                    });
                }
                if (this.permissions.canUpdateEventsInBulk) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'batch-event-update',
                        icon: 'cpa-icon cpa-icon-pencil-square-o',
                        text: 'bulkactionsmenu.BatchEventUpdate',
                        enabled: false,
                        click: this.batchEventUpdate
                    });

                }
                if (this.permissions.canPoliceInBulk && this.isReleaseGreaterThan14) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'case-bulk-policing',
                        icon: 'cpa-icon cpa-icon-gears',
                        text: 'bulkactionsmenu.BulkPolicing',
                        enabled: false,
                        click: this.bulkPolicing
                    });
                }
                if (this.permissions.canViewCaseDataComparison) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'case-data-comparison',
                        icon: 'cpa-icon cpa-icon-columns',
                        text: 'bulkactionsmenu.CaseDataComparison',
                        enabled: false,
                        click: this.caseDataComparison
                    });
                }
                if (!this.viewData.isExternal) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'sanity-check',
                        icon: 'cpa-icon cpa-icon-check-square-o',
                        text: 'bulkactionsmenu.SanityCheck',
                        enabled: false,
                        click: this.applySanityCheck
                    });
                }

                break;
            case queryContextKeyEnum.wipOverview:
                const wp: WipOverviewSearchPermissions = this.permissions;
                if (wp.canMaintainDebitNote) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'create-single-bill',
                        icon: 'cpa-icon cpa-icon-file-text-o',
                        text: 'wipOverviewSearch.bulkActionMenu.createSingleBill',
                        enabled: false,
                        click: this.createSingleBill
                    });
                    if (isHosted) {
                        menuItems.push({
                            ...new IpxBulkActionOptions(),
                            id: 'create-multiple-bill',
                            icon: 'cpa-icon cpa-icon-file-stack-text-o',
                            text: 'wipOverviewSearch.bulkActionMenu.createMultipleBill',
                            enabled: false,
                            click: this.createMultipleBill
                        });
                    }
                }
                break;
            default:
                break;
        }
        const billingWorksheetMenus = this.billingWorksheetProvider.getConfigurationActionMenuItems(isHosted, viewData);
        if (billingWorksheetMenus && billingWorksheetMenus.length > 0) {
            billingWorksheetMenus.map((item) => {
                menuItems.push(item);
            });
        }

        const taskPlannerMenus = this.taskPlannerProvider.getConfigurationActionMenuItems(queryContextKey, viewData);
        taskPlannerMenus.map((item) => {
            menuItems.push(item);
        });

        return menuItems;
    };

    createSingleBill = (resultGrid: IpxKendoGridComponent) => {
        this.handleWipOverviewActionMenuEvent(resultGrid, WipOverviewOperationType.createSingleBill);
    };

    createMultipleBill = (resultGrid: IpxKendoGridComponent) => {
        this.handleWipOverviewActionMenuEvent(resultGrid, WipOverviewOperationType.createMultipleBill);
    };

    handleWipOverviewActionMenuEvent = (resultGrid: IpxKendoGridComponent, type: string) => {

        switch (type) {
            case WipOverviewOperationType.createMultipleBill:
            case WipOverviewOperationType.createSingleBill:

                const filterRequest = {
                    searchRequestParams: {
                        queryKey: this.viewData.queryKey,
                        criteria: { XmlSearchRequest: this.viewData.filter },
                        params: {},
                        queryContext: this.queryContextKey,
                        selectedColumns: null,
                        presentationType: null
                    },
                    hasAllSelected: resultGrid.getRowSelectionParams().isAllPageSelect,
                    deSelectedIds: resultGrid.getRowSelectionParams().allDeSelectIds
                };

                this.searchTypeMenuProviderService.getAdditionalViewDataFromFilterCriteria(filterRequest).subscribe((response: any) => {
                    const selectedItems = resultGrid.getRowSelectionParams().isAllPageSelect ? response.searchResult.rows : resultGrid.getRowSelectionParams().allSelectedItems;
                    const createBillList = _.map(selectedItems, (item: any) => {
                        return {
                            debtorKey: item.debtorKey,
                            caseKey: item.totalamount.link.caseKey,
                            allocatedDebtorKey: item.allocatedDebtorKey,
                            fromItemDate: response.filterFromDate,
                            toItemDate: response.filterToDate,
                            isNonRenewalWip: response.isNonRenewalWip,
                            isRenewalWip: response.isRenewalWip,
                            isUseRenewalDebtor: response.isUseRenewalDebtor,
                            entityId: item.entityKey
                        };
                    });

                    if (type === WipOverviewOperationType.createSingleBill) {
                        this.wipOverviewProvider.createSingleBill(createBillList, this.viewData.entities);
                    } else {
                        this.windowParentMessagingService.postNavigationMessage({
                            args: [
                                'CreateBills',
                                JSON.stringify(createBillList),
                                this.translate.instant('wipOverviewSearch.bulkActionMenu.' + type),
                                false
                            ]
                        });
                    }
                });
                break;
            default:
                break;
        }
    };

    bulkOperationWithCaseIds = (resultGrid: IpxKendoGridComponent, type: string) => {
        let selectedRowKeys;
        let exportFilter: any = {};
        const defaultCriteria: any = {};
        defaultCriteria.searchRequest = [{ anySearch: { operator: 2, value: this.viewData.q } }];
        this.filter = this.viewData.filter ? this.viewData.filter : defaultCriteria;

        if (resultGrid.getRowSelectionParams().isAllPageSelect) {
            exportFilter = this.caseSerachResultFilterService.getFilter(resultGrid.getRowSelectionParams().isAllPageSelect, resultGrid.getRowSelectionParams().allSelectedItems,
                resultGrid.getRowSelectionParams().allDeSelectedItems, this.config.rowKeyField, this.filter, this.searchConfiguration);
            this.caseService.caseIdsForBulkOperations$(exportFilter, this.viewData.queryContextKey, this.viewData.queryKey, exportFilter.deselectedIds).subscribe((res: any) => {
                this.selectedCaseIds = res.join(',');
                selectedRowKeys = _.pluck(resultGrid.items, 'rowKey').join(',');
                this.caseSerachResultFilterService.persistSelectedItems(resultGrid.items);

                this.manageBulkOperation(this.selectedCaseIds, selectedRowKeys, type);
            });
        } else if (_.any(resultGrid.getRowSelectionParams().allSelectedItems)) {
            this.selectedCaseIds = this.getSelectedCaseKeys(resultGrid);
            selectedRowKeys = resultGrid.getSelectedItems('rowKey').join(',');
            this.caseSerachResultFilterService.persistSelectedItems(resultGrid.getRowSelectionParams().allSelectedItems);
            this.manageBulkOperation(this.selectedCaseIds, selectedRowKeys, type);
        }
    };

    manageBulkOperation = (caseIds: string, caseKeys: string, type: string) => {
        switch (type) {
            case OperationType.bulkUpdate:
                this.bulkUpdateWithCaseIds(caseIds, caseKeys);
                break;
            case OperationType.batchEventUpdate:
                this.batchEventUpdateWithCaseIds(caseIds);
                break;
            case OperationType.sanityCheck:
                this.applySanityCheckWithCaseIds(caseIds);
                break;
            case OperationType.globalNameChange:
                this.globalNameChangeWithCaseIds(caseIds);
                break;
            case OperationType.caseDataComparison:
                this.caseDataComparisonWithCaseIds(caseIds);
                break;
            case OperationType.bulkPolicingRequest:
                this.bulkPolicingWithCaseIds(caseIds);
                break;
            case OperationType.addToCaselist:
                this.caselistModalSevice.openCaselistModal(caseIds);
                break;
            default:
                break;
        }
    };

    bulkUpdate = (resultGrid: IpxKendoGridComponent) => {
        this.bulkOperationWithCaseIds(resultGrid, OperationType.bulkUpdate);
    };

    bulkUpdateWithCaseIds = (selectedCaseIds: string, selectedRowKeys: string) => {
        this.localSettings.keys.bulkUpdate.data.setSession({ caseIds: selectedCaseIds, selectedRowKeys });
        if (this.isHosted) {
            const url = '#/bulkupdate';
            window.open(url, '_blank');
        } else {
            this.stateService.go('bulk-edit', null);
        }
    };

    batchEventUpdate = (resultGrid: IpxKendoGridComponent) => {
        this.bulkOperationWithCaseIds(resultGrid, OperationType.batchEventUpdate);
    };

    batchEventUpdateWithCaseIds = (selectedCaseIds: string) => {
        this.caseService.getBatchEventUpdateUrl(selectedCaseIds).subscribe((response) => {
            if (response.result) {
                this.windowRef.nativeWindow.open(response.result, '_blank');
            }
        });
    };

    bulkPolicing = (resultGrid: IpxKendoGridComponent) => {
        this.bulkOperationWithCaseIds(resultGrid, OperationType.bulkPolicingRequest);
    };

    bulkPolicingWithCaseIds = (selectedCaseIds: string) => {
        // open Modal window
        this.modalRef = this.modalService.openModal(BulkPolicingRequestComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                selectedCases: selectedCaseIds.split(',').map(Number)
            }
        });

        this.modalRef.content.onClose.subscribe(value => {
            if (value) {
                this.notificationService.success('bulkPolicing.requestSubmitted');
            }
        });
    };

    caseDataComparison = (resultGrid: IpxKendoGridComponent) => {
        this.bulkOperationWithCaseIds(resultGrid, OperationType.caseDataComparison);
    };

    caseDataComparisonWithCaseIds = (selectedCaseIds: string) => {
        this.storeResolvedItemsService.add(selectedCaseIds)
            .subscribe((tempStorageId) => {
                this.windowRef.nativeWindow.open(this.commonUtilityService.getBasePath() + '#/casecomparison/inbox?caselist=&ts=' + tempStorageId, '_blank');
            });
    };

    applySanityCheck = (resultGrid: IpxKendoGridComponent) => {
        this.bulkOperationWithCaseIds(resultGrid, OperationType.sanityCheck);
    };

    addToCaselist = (resultGrid: IpxKendoGridComponent) => {
        this.bulkOperationWithCaseIds(resultGrid, OperationType.addToCaselist);
    };

    applySanityCheckWithCaseIds = (selectedCaseIds: string) => {
        this.caseService.applySanityCheck(selectedCaseIds.split(',').map(Number)).subscribe((response) => {
            if (response.status) {
                this.notificationService.success('sanityCheck.requestSubmitted');
            }
        });
    };

    globalNameChange = (resultGrid: IpxKendoGridComponent) => {
        this.bulkOperationWithCaseIds(resultGrid, OperationType.globalNameChange);
    };

    globalNameChangeWithCaseIds = (selectedCaseIds: string) => {
        this.windowParentMessagingService.postNavigationMessage({ args: ['GlobalNameChange', selectedCaseIds] });
    };

    private readonly getSelectedCaseKeys = (resultGrid: IpxKendoGridComponent): string => {
        const selectedItems = resultGrid.getSelectedItems('caseKey');

        return _.any(selectedItems) ? selectedItems.join(',') : null;
    };

}

enum OperationType {
    sanityCheck = 'SanityCheck',
    bulkUpdate = 'BulkUpdate',
    batchEventUpdate = 'BatchEventUpdate',
    caseDataComparison = 'CaseDataComparison',
    globalNameChange = 'GlobalNameChange',
    bulkPolicingRequest = 'BulkPolicingRequest',
    addToCaselist = 'AddToCaselist'
}

enum WipOverviewOperationType {
    createSingleBill = 'createSingleBill',
    createMultipleBill = 'createMultipleBill'
}