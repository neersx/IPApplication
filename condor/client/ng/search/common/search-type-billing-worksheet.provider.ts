import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import * as angular from 'angular';
import { MessageBroker } from 'core/message-broker';
import { ExportContentType } from 'search/results/export.content.model';
import { CaseSearchPermissions, WipOverviewSearchPermissions } from 'search/results/search-results.data';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { TaskMenuItem } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import * as _ from 'underscore';
import { SearchTypeBillingWorksheetProviderService } from './search-type-billing-worksheet-provider.service';
import { queryContextKeyEnum } from './search-type-config.provider';
import { SearchTypeMenuProviderService } from './search-type-menu-provider.service';

@Injectable()
export class SearchTypeBillingWorksheetProvider {
    permissions: any;
    queryContextKey: number;
    viewData: any;
    exportContentTypeMapper: Array<ExportContentType>;

    constructor(
        private readonly billingWorksheetProviderService: SearchTypeBillingWorksheetProviderService,
        private readonly notificationService: NotificationService,
        private readonly translate: TranslateService,
        private readonly searchTypeMenuProviderService: SearchTypeMenuProviderService,
        private readonly messageBroker: MessageBroker) { }

    initializeContext = (permissions: any, queryContextKey: number, exportContentTypeMapper: Array<ExportContentType>): void => {
        this.queryContextKey = queryContextKey;
        this.exportContentTypeMapper = exportContentTypeMapper;
        if (permissions) {
            switch (queryContextKey) {
                case queryContextKeyEnum.wipOverview:
                    this.permissions = permissions as CaseSearchPermissions;
                    break;
                default:
                    break;
            }
        }
    };

    getConfigurationActionMenuItems = (isHosted, viewData: any): Array<TaskMenuItem> => {
        this.viewData = viewData;
        let tasks = [];
        switch (this.queryContextKey) {
            case queryContextKeyEnum.wipOverview:
                const wsp: WipOverviewSearchPermissions = this.permissions;
                tasks = this.configureWipOverviewSearchActionMenus(wsp, isHosted);
                break;
            default:
                break;
        }

        return tasks;
    };

    private configureWipOverviewSearchActionMenus(wsp: WipOverviewSearchPermissions, isHosted: boolean): Array<IpxBulkActionOptions> {
        const menuItems = [];
        if (this.viewData.reportProviderInfo && this.viewData.reportProviderInfo.exportFormats && this.viewData.reportProviderInfo.exportFormats.length > 0 && wsp.canCreateBillingWorksheet) {
            const billingWorksheet = {
                ...new IpxBulkActionOptions(),
                id: 'create-billing-worksheet',
                icon: 'cpa-icon cpa-icon-table',
                text: 'bulkactionsmenu.createBillingWorksheet',
                enabled: 'single-selection',
                items: []
            };

            const createBillingWorksheetExtended = {
                ...new IpxBulkActionOptions(),
                id: 'create-billing-worksheet-extended',
                icon: 'cpa-icon cpa-icon-table',
                text: 'bulkactionsmenu.createBillingWorksheetExtended',
                enabled: 'single-selection',
                items: []
            };

            menuItems.push(billingWorksheet);
            menuItems.push(createBillingWorksheetExtended);

            this.viewData.reportProviderInfo.exportFormats.forEach((format) => {

                const menu = {
                    id: format.exportFormatKey,
                    text: format.exportFormatDescription,
                    enabled: true
                };

                billingWorksheet.items.push(angular.extend({}, menu, {
                    click: (resultGrid: IpxKendoGridComponent): any => {
                        this.makeBillingWorkSheetRequest(resultGrid, format.exportFormatKey, false);
                    }
                }));

                createBillingWorksheetExtended.items.push(angular.extend({}, menu, {
                    click: (resultGrid: IpxKendoGridComponent): any => {
                        this.makeBillingWorkSheetRequest(resultGrid, format.exportFormatKey, true);
                    }
                }));

            });
        }

        return menuItems;
    }

    makeBillingWorkSheetRequest = (resultGrid: IpxKendoGridComponent, exportFormat: BillingReportExportFormat, hasExtendedWorkSheet: Boolean) => {
        if (resultGrid.getRowSelectionParams().isAllPageSelect) {
            const filterRequest = {
                searchRequestParams: {
                    queryKey: '',
                    criteria: { XmlSearchRequest: this.viewData.xmlCriteriaExecuted },
                    params: {},
                    queryContext: this.queryContextKey,
                    selectedColumns: null,
                    presentationType: null
                },
                hasAllSelected: resultGrid.getRowSelectionParams().isAllPageSelect,
                deSelectedIds: resultGrid.getRowSelectionParams().allDeSelectIds
            };

            this.searchTypeMenuProviderService.getAdditionalViewDataFromFilterCriteria(filterRequest).subscribe((response: any) => {
                this.submitBillingWorkSheetRequest(response.searchResult.rows, exportFormat, hasExtendedWorkSheet);
            });
        } else {
            this.submitBillingWorkSheetRequest(resultGrid.getRowSelectionParams().allSelectedItems, exportFormat, hasExtendedWorkSheet);
        }
    };

    submitBillingWorkSheetRequest = (selectedItems: any, exportFormat: BillingReportExportFormat, hasExtendedWorkSheet: Boolean) => {
        const items = _.map(selectedItems, (item: any) => {
            return {
                entityKey: item.entityKey,
                wipNameKey: item.wipNameKey,
                caseKey: item.caseKey
            };
        });

        const request = {
            xmlFilterCriteria: this.viewData.xmlCriteriaExecuted,
            items,
            reportExportFormat: BillingReportExportFormat[exportFormat],
            reportName: hasExtendedWorkSheet ? 'BillingWorksheetExtended' : 'BillingWorksheet',
            connectionId: this.messageBroker.getConnectionId()
        };

        this.billingWorksheetProviderService.genrateBillingWorkSheet(request)
            .subscribe((contentId) => {
                if (contentId > 0) {
                    const format: string = request.reportExportFormat.toString() === BillingReportExportFormat.excel.toString() ? this.translate.instant('bulkactionsmenu.excel') :
                        (request.reportExportFormat.toString() === BillingReportExportFormat.word.toString() ? this.translate.instant('bulkactionsmenu.word') : exportFormat.toString().toUpperCase());

                    this.exportContentTypeMapper.push({
                        contentId,
                        reportFormat: format
                    });

                    this.notificationService
                        .success(this.translate.instant('exportSubmitMessage', {
                            value: format
                        }), null, this.viewData.billingWorksheetTimeout);
                }
            });
    };
}

enum BillingReportExportFormat {
    pdf = 9501,
    word = 9502,
    excel = 9503,
    xml = 9504,
    qrp = 9505,
    csv = 9506,
    mhtml = 9507
}