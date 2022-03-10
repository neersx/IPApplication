import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { StoreResolvedItemsServiceMock } from 'core/storeresolveditems.mock';
import { WindowRefMock } from 'core/window-ref.mock';
import { CaseSearchServiceMock, NotificationServiceMock, StateServiceMock, TranslateServiceMock } from 'mocks';
import { FeatureDetectionMock } from 'mocks/feature-detection.mock';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { ExportContentType } from 'search/results/export.content.model';
import { CaseSerachResultFilterService } from 'search/results/search-results.filter.service';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { SearchTypeActionMenuProvider } from './search-type-action-menus.provider';
import { SearchTypeBillingWorksheetProvidereMock } from './search-type-billing-worksheet.provider.mock';
import { SearchTypeMenuProviderServiceMock } from './search-type-menu.provider.mock';

describe('SearchTypeActionMenuProvider', () => {

    const localSettings = new LocalSettingsMock();
    const stateService = new StateServiceMock();
    const caseService = new CaseSearchServiceMock();
    const translateServiceMock = new TranslateServiceMock();
    const searchTypeMenuProviderServiceMock = new SearchTypeMenuProviderServiceMock();
    const windowParentMessagingService = new WindowParentMessagingServiceMock();
    const storeResolvedItemsService = new StoreResolvedItemsServiceMock();
    const windowRef = new WindowRefMock();
    const commonUtilityService = new CommonUtilityServiceMock();
    const notificationService = new NotificationServiceMock();
    const billingWorksheetMock = new SearchTypeBillingWorksheetProvidereMock();
    const caseSerachResultFilterService = new CaseSerachResultFilterService();
    const modalService = new ModalServiceMock();
    const featureDetectionMock = new FeatureDetectionMock();
    const resultGrid = new IpxKendoGridComponentMock();
    const caselistModalServiceMock = {
        openCaselistModal: jest.fn()
    };
    const taskPlannerProviderMock = {
        getConfigurationActionMenuItems: jest.fn().mockReturnValue([])
    };
    let service: SearchTypeActionMenuProvider;
    const caseIds = '123, 234, 345';
    const caseKeys = '345';
    const wipOverProvider = {};

    beforeEach(() => {
        caseSerachResultFilterService.persistSelectedItems = jest.fn();
        caseSerachResultFilterService.getPersistedSelectedItems = jest.fn();
        service = new SearchTypeActionMenuProvider(
            localSettings as any,
            stateService as any,
            caseService as any,
            windowParentMessagingService as any,
            storeResolvedItemsService as any,
            windowRef as any,
            commonUtilityService as any,
            notificationService as any,
            caseSerachResultFilterService as any,
            searchTypeMenuProviderServiceMock as any,
            translateServiceMock as any,
            billingWorksheetMock as any,
            modalService as any,
            featureDetectionMock as any,
            caselistModalServiceMock as any,
            taskPlannerProviderMock as any,
            wipOverProvider as any
        );
    });

    it('should load action menu configuration service', () => {
        expect(service).toBeTruthy();
    });

    it('should check bulk operations with caseIds', () => {
        resultGrid.getRowSelectionParams = jest.fn().mockReturnValue({
            isAllPageSelect: false,
            allSelectedItems: [{ id: '123' }]
        });
        spyOn(service, 'manageBulkOperation');
        service.viewData = {
            q: ''
        };
        service.bulkOperationWithCaseIds(resultGrid as any, OperationType.bulkUpdate);
        expect(service.manageBulkOperation).toBeCalled();
    });

    describe('manageBulkOperation', () => {

        it('should call bulkUpdateWithCaseIds', () => {
            spyOn(service, 'bulkUpdateWithCaseIds');
            service.manageBulkOperation(caseIds, caseKeys, OperationType.bulkUpdate);
            expect(service.bulkUpdateWithCaseIds).toBeCalled();
        });
        it('should call bulkPolicingWithCaseIds', () => {
            spyOn(service, 'bulkPolicingWithCaseIds');
            service.manageBulkOperation(caseIds, caseKeys, OperationType.bulkPolicingRequest);
            expect(service.bulkPolicingWithCaseIds).toBeCalled();
        });

        it('should call batchEventUpdateWithCaseIds', () => {
            spyOn(service, 'batchEventUpdateWithCaseIds');
            service.manageBulkOperation(caseIds, caseKeys, OperationType.batchEventUpdate);
            expect(service.batchEventUpdateWithCaseIds).toBeCalled();
        });

        it('should call applySanityCheckWithCaseIds', () => {
            spyOn(service, 'applySanityCheckWithCaseIds');
            service.manageBulkOperation(caseIds, caseKeys, OperationType.sanityCheck);
            expect(service.applySanityCheckWithCaseIds).toBeCalled();
        });

        it('should call addToCaselist', () => {
            service.permissions = { canAddCaseList: true, canUpdateCaseList: true };
            service.manageBulkOperation(caseIds, caseKeys, OperationType.addToCaselist);
            expect(caselistModalServiceMock.openCaselistModal).toBeCalledWith(caseIds);
        });

        it('should call globalNameChangeWithCaseIds', () => {
            spyOn(service, 'globalNameChangeWithCaseIds');
            service.manageBulkOperation(caseIds, caseKeys, OperationType.globalNameChange);
            expect(service.globalNameChangeWithCaseIds).toBeCalled();
        });

        it('should call caseDataComparisonWithCaseIds', () => {
            spyOn(service, 'caseDataComparisonWithCaseIds');
            service.manageBulkOperation(caseIds, caseKeys, OperationType.caseDataComparison);
            expect(service.caseDataComparisonWithCaseIds).toBeCalled();
        });
    });
    describe('check for bulk policing request menu item on case search results', () => {
        let permissions: any;
        let querycontexKey: number;
        let viewData: any;
        let exportContentTypeMaper: Array<ExportContentType>;
        beforeEach(() => {
            querycontexKey = 2;
            viewData = {
                queryContextKey: querycontexKey
            };
            exportContentTypeMaper = null;
        });
        it('menu item is available if permission is granted', () => {
            permissions = {
                canPoliceInBulk: true
            };
            service.isReleaseGreaterThan14 = true;
            service.initializeContext(permissions, querycontexKey, exportContentTypeMaper, false);
            const menus = service.getConfigurationActionMenuItems(querycontexKey, viewData, false);
            expect(menus.length).toBe(2);
            expect(menus[0].id).toEqual('case-bulk-policing');
        });
        it('menu item is not available if permission is not granted', () => {
            permissions = {
                canPoliceInBulk: false
            };
            service.isReleaseGreaterThan14 = true;
            service.initializeContext(permissions, querycontexKey, exportContentTypeMaper, false);
            const menus = service.getConfigurationActionMenuItems(querycontexKey, viewData, false);
            expect(menus.length).toBe(1);
        });
        it('menu item is not available for release versions less than 14', () => {
            permissions = {
                canPoliceInBulk: false
            };
            service.isReleaseGreaterThan14 = false;
            service.initializeContext(permissions, querycontexKey, exportContentTypeMaper, false);
            const menus = service.getConfigurationActionMenuItems(querycontexKey, viewData, false);
            expect(menus.length).toBe(1);
        });
    });
    describe('check for createBill action menu item on wipoverview', () => {

        let permissions: any;
        let isHosted;
        let querycontexKey: number;
        let viewData: any;
        let exportContentTypeMaper: Array<ExportContentType>;
        beforeEach(() => {
            permissions = {
                canMaintainDebitNote: true
            };
            querycontexKey = 200;
            viewData = {
                queryContextKey: querycontexKey
            };
            exportContentTypeMaper = [{ contentId: 1, reportFormat: 'PDF' }];
        });

        it('menu item is not available if not hosted', () => {

            service.initializeContext(permissions, querycontexKey, exportContentTypeMaper, false);
            const menus = service.getConfigurationActionMenuItems(querycontexKey, viewData, isHosted);
            expect(menus.length).toBe(1);
            expect(menus[0].id).toEqual('create-single-bill');
        });

        it('menu item is available if hosted', () => {
            isHosted = true;
            service.initializeContext(permissions, querycontexKey, exportContentTypeMaper, false);
            const menus = service.getConfigurationActionMenuItems(querycontexKey, viewData, isHosted);
            expect(menus.length).toBe(2);
            expect(menus[0].id).toEqual('create-single-bill');
            expect(menus[1].id).toEqual('create-multiple-bill');
        });

        it('menu item is not available if permission is not granted', () => {
            isHosted = true;
            permissions = {
                canMaintainDebitNote: false
            };
            service.initializeContext(permissions, querycontexKey, exportContentTypeMaper, false);
            const menus = service.getConfigurationActionMenuItems(querycontexKey, viewData, isHosted);
            expect(menus.length).toBe(0);
        });
    });

});

enum OperationType {
    sanityCheck = 'SanityCheck',
    bulkUpdate = 'BulkUpdate',
    batchEventUpdate = 'BatchEventUpdate',
    caseDataComparison = 'CaseDataComparison',
    globalNameChange = 'GlobalNameChange',
    bulkPolicingRequest = 'BulkPolicingRequest',
    addToCaselist = 'AddToCaselist'
}