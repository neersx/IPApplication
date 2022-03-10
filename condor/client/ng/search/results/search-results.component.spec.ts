import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import * as angular from 'angular';
import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { StoreResolvedItemsServiceMock } from 'core/storeresolveditems.mock';
import { WindowRefMock } from 'core/window-ref.mock';
import { BehaviorSubjectMock, CaseSearchHelperServiceMock, CaseSearchServiceMock, ChangeDetectorRefMock, FileDownloadService, LocalSettingsMocks, MessageBroker, NgZoneMock, NotificationServiceMock, Renderer2Mock, SearchExportServiceMock, TranslateServiceMock } from 'mocks';
import { FeatureDetectionMock } from 'mocks/feature-detection.mock';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { Observable, of } from 'rxjs';
import { SearchTypeActionMenuProvider } from 'search/common/search-type-action-menus.provider';
import { SearchTypeBillingWorksheetProvidereMock } from 'search/common/search-type-billing-worksheet.provider.mock';
import { SearchTypeMenuProviderServiceMock } from 'search/common/search-type-menu.provider.mock';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import * as _ from 'underscore';
import { ReportExportFormat } from './report-export.format';
import { SearchResultsComponent } from './search-results.component';
import { SearchResultsViewData } from './search-results.data';
import { SearchResultColumn } from './search-results.model';

describe('CaseSearchResultsComponent', () => {
    let c: SearchResultsComponent;
    let messageBroker: any;
    let cdr: ChangeDetectorRefMock;
    let translateServiceMock = new TranslateServiceMock();
    const searchTypeMenuProviderServiceMock = new SearchTypeMenuProviderServiceMock();
    const caseHelpermock = new CaseSearchHelperServiceMock();
    const zone = new NgZoneMock();
    const localSettingsMock = new LocalSettingsMocks();
    const dateServiceSpy = { formatDate: jest.fn(), dateFormat: '', culture: 'en-US' };
    const stateServiceSpy = { params: { id: '3' }, go: () => undefined };
    const mockSearchResultService = { getColumns$: jest.fn().mockReturnValue(new Observable()), getSearch$: jest.fn().mockReturnValue(new Observable()), getSavedCaseSearch$: jest.fn().mockReturnValue(new Observable()), exportToCpaXml: jest.fn().mockReturnValue(new Observable()) };
    const mockCaseSearchService = {};
    const searchExportServiceMock = new SearchExportServiceMock();
    const transitionServiceSpy = { onBefore: jest.fn() };
    const navigationServiceSpy = { tempReturnNextRecordSetFromCache: jest.fn(), getCurrentPageIndex: jest.fn(), clearLoadedData: jest.fn() };
    const caselistModalSevice = {};
    const caseServiceMock = new CaseSearchServiceMock();
    const windowParentMessagingServiceMock = new WindowParentMessagingServiceMock();
    const storeResolvedItemsServiceMock = new StoreResolvedItemsServiceMock();
    const windowRefMock = new WindowRefMock();
    const commonUtilityServiceMock = new CommonUtilityServiceMock();
    const notificationServiceMock = new NotificationServiceMock();
    const billingWorksheetMock = new SearchTypeBillingWorksheetProvidereMock();
    const modalService = new ModalServiceMock();
    const featureDetectionMock = new FeatureDetectionMock();

    const wipOverviewProvider = {};
    const billSearchProvider = { initializeContext: jest.fn(), manageTaskOperation: jest.fn() };
    const caseSearchResultFilterService = {
        getFilter: jest.fn().mockReturnValue({ exportFilter: {} }),
        persistSelectedItems: jest.fn(),
        getPersistedSelectedItems: jest.fn()
    };
    const searchTypeTaskPlannerProvider = {
        getConfigurationActionMenuItems: jest.fn().mockReturnValue([])
    };
    const actionMenuProviderSpy = new SearchTypeActionMenuProvider(
        localSettingsMock as any,
        stateServiceSpy as any,
        caseServiceMock as any,
        windowParentMessagingServiceMock as any,
        storeResolvedItemsServiceMock as any,
        windowRefMock as any,
        commonUtilityServiceMock as any,
        notificationServiceMock as any,
        caseSearchResultFilterService as any,
        searchTypeMenuProviderServiceMock as any,
        translateServiceMock as any,
        billingWorksheetMock as any,
        modalService as any,
        featureDetectionMock as any,
        caselistModalSevice as any,
        searchTypeTaskPlannerProvider as any,
        wipOverviewProvider as any
    );
    const taskMenuProviderMock = {
        getConfigurationTaskMenuItems: jest.fn(() => { return new Array<any>(); }),
        initializeContext: jest.fn()
    };
    const searchResultPermissionsEvaluatorMock = {
        checkForAtleaseOneTaskMenuPermission: jest.fn(),
        initializeContext: jest.fn()
    };
    const stringColumn: any = {
        title: 'textColTitle',
        format: 'anyColumn',
        id: 'strCol',
        isColumnFreezed: false
    };
    const dateColumn: any = {
        title: 'dateColTitle',
        format: 'date',
        id: 'dateCol',
        isColumnFreezed: false
    };
    const hyperlinkColumn: any = {
        title: 'hyperColTitle',
        format: 'string',
        id: 'hyperCol',
        isHyperlink: true,
        isColumnFreezed: false
    };
    const imageColumn: any = {
        title: 'imageColTitle',
        format: 'image key',
        id: 'imageCol',
        isColumnFreezed: false
    };

    let mockResponse: any;
    let mockResults: any;
    let exportFormat: ReportExportFormat;
    const fileDownloadService = new FileDownloadService();
    let behaviorSubjectMock;
    const renderer = new Renderer2Mock();
    beforeEach(() => {
        behaviorSubjectMock = new BehaviorSubjectMock();
        translateServiceMock = new TranslateServiceMock();
        cdr = new ChangeDetectorRefMock();
        const rootScopeService = new RootScopeServiceMock();
        messageBroker = new MessageBroker();
        c = new SearchResultsComponent(rootScopeService as any,
            mockSearchResultService as any,
            dateServiceSpy as any,
            stateServiceSpy as any,
            localSettingsMock as any,
            searchExportServiceMock as any,
            transitionServiceSpy as any,
            navigationServiceSpy as any,
            notificationServiceMock as any,
            cdr as any,
            caseHelpermock as any,
            translateServiceMock as any,
            new WindowParentMessagingServiceMock() as any,
            mockCaseSearchService as any,
            actionMenuProviderSpy as any,
            caseSearchResultFilterService as any,
            taskMenuProviderMock as any,
            searchResultPermissionsEvaluatorMock as any,
            fileDownloadService as any,
            zone as any,
            messageBroker,
            renderer as any,
            commonUtilityServiceMock as any,
            billSearchProvider as any);
        c.viewData = new SearchResultsViewData();
        c.queryContextKey = 2;
        c.viewData = {
            exportLimit: 5,
            billingWorksheetTimeout: 1,
            hasOffices: false,
            hasFileLocation: false,
            q: '1234',
            filter: [{ anySearch: { operator: 2, value: c.viewData.q } }],
            queryKey: 32,
            queryName: 'Saved Search',
            isExternal: false,
            searchQueryKey: true,
            hasDueDatePresentation: false,
            queryContext: 2,
            reportProviderInfo: null,
            programs: [{
                id: 'case',
                name: 'Case',
                isDefault: true
            },
            {
                id: 'caseEntry',
                name: 'Case Entry',
                isDefault: false
            },
            {
                id: 'caseMain',
                name: 'Case Maintenance',
                isDefault: false
            }],
            backgroundProcessResultTitle: null,
            globalProcessKey: null,
            presentationType: null,
            permissions: {
                canShowLinkforInprotechWeb: true
            }
        };
        c._resultsGrid = new IpxKendoGridComponentMock() as any;
    });

    it('should create the component', () => {
        expect(c).toBeTruthy();
    });

    it('should initialize the fields and methods', () => {
        c.ngOnInit();

        expect(c.queryKey).toBe(32);
        expect(c.queryParams).toBeDefined();
        expect(c.filter).toBeDefined();
        expect(billSearchProvider.initializeContext).toHaveBeenCalled();
    });

    it('validate setEntry points', () => {

        c.ngOnInit();
        expect(c.searchResultEntryPoint).toBe(2);

        c.viewData.filter = {};
        c.viewData.queryKey = null;
        c.ngOnInit();
        expect(c.searchResultEntryPoint).toBe(3);
    });

    it('should show programs list from viewdata if programs more than 1', () => {
        c.queryContextKey = 2;
        c.viewData.programs = [{
            id: 'case',
            name: 'Case',
            isDefault: true
        }, {
            id: 'case2',
            name: 'Case2',
            isDefault: false
        }];

        c.ngOnInit();
        expect(c.actions.length).toBe(5);
    });

    it('should set default program from list from viewdata', () => {
        c.ngOnInit();
        expect(c.defaultProgram).toBe('case');
    });

    it('should process Downloadable Contents', () => {
        const content = [{ contentId: 1, status: 'ready.to.download' }];
        c.dwlContentId$ = behaviorSubjectMock;
        c.bgContentId$ = behaviorSubjectMock;
        spyOn(c.dwlContentId$, 'next');

        c.processContents(content);
        expect(c.dwlContentId$.next).toHaveBeenCalledWith(1);
    });

    it('should process background Contents', () => {
        const content = [{ contentId: 5, status: 'processed.in.background' }];
        c.dwlContentId$ = behaviorSubjectMock;
        c.bgContentId$ = behaviorSubjectMock;
        spyOn(c.bgContentId$, 'next');

        c.processContents(content);
        expect(c.bgContentId$.next).toHaveBeenCalledWith(5);
    });

    it('should not show programs list if programs less than 2', () => {
        c.queryContextKey = 10;
        c.viewData.programs = [{
            id: 'name',
            name: 'name',
            isDefault: true
        }];

        c.ngOnInit();
        expect(c.actions.length).toEqual(5);
    });

    describe('Grid initialisation', () => {
        const searchColumns: any = [stringColumn, dateColumn, hyperlinkColumn, imageColumn];

        beforeEach(() => {
            mockResponse = { totalRows: 40, columns: searchColumns, rows: [] };
            mockResults = {
                filterable: true,
                pageable: true,
                pageSize: 20,
                read$: mockResponse,
                reorderable: true,
                sortable: true,
                selectable: { mode: 'single' },
                locked: false
            };
        });

        it('should return column locked property false when no column is freezed', () => {
            c.ngOnInit();
            const returnedColumns = c.buildColumns(searchColumns);
            expect(c.anyColumnLocked).toBeFalsy();
            expect(returnedColumns[0].locked).toBeFalsy();
            expect(returnedColumns[1].locked).toBeFalsy();
            expect(returnedColumns[2].locked).toBeFalsy();
            expect(returnedColumns[3].locked).toBeFalsy();
        });

        it('should return column locked property true when column is freezed', () => {
            const linkColumn: any = {
                title: 'hyperColTitle',
                format: 'string',
                id: 'hyperCol',
                isHyperlink: true,
                isColumnFreezed: true
            };
            const columns: any = [linkColumn, stringColumn, dateColumn, imageColumn];

            const parentElement = angular.element('<div></div>');
            angular.element(document.body).append('<ipx-sticky-header></ipx-sticky-header>').prepend(parentElement);

            const returnedColumns = c.buildColumns(columns);
            expect(c.anyColumnLocked).toBeTruthy();
            expect(returnedColumns[0].locked).toBeTruthy();
            expect(returnedColumns[1].locked).toBeFalsy();
            expect(returnedColumns[2].locked).toBeFalsy();
            expect(returnedColumns[3].locked).toBeFalsy();
        });

        it('should return data and pagination to grid', () => {

            c.ngOnInit();
            const readResult: any = mockResults;
            jest.spyOn(mockSearchResultService, 'getColumns$').mockReturnValue(searchColumns);
            expect(mockSearchResultService.getColumns$).toBeCalled();
            expect(readResult.pageSize).toBe(20);
            expect(readResult.pageable).toBe(true);
            expect(readResult.selectable).toBeDefined();
            expect(readResult.read$.columns).toBe(searchColumns);
        });

        it('should set total rows into the component', () => {

            const spy = jest.spyOn(mockSearchResultService, 'getSearch$');
            spy.mockReturnValue(searchColumns);
            expect(c.totalRecords).not.toBe(40);
        });

        it('should call  hasBooleanValue', () => {
            let data = 'true';
            expect(c.hasBooleanValue(data)).toEqual(true);
            data = 'false';
            expect(c.hasBooleanValue(data)).toEqual(true);
            data = '0';
            expect(c.hasBooleanValue(data)).toEqual(false);
        });
        it('should call export service\'s exportToCpaXml with the right filter, when export to cpa xml option is selected', () => {
            c.filter = { prop: 'some value' };
            searchExportServiceMock.exportToCpaXml.mockReturnValue(of({}));
            c.cpaXmlImport();
            expect(searchExportServiceMock.exportToCpaXml).toHaveBeenCalledWith({ ...c.filter }, 2);
        });

        it('should format columns', () => {
            dateServiceSpy.dateFormat = 'DD-MMM-YYYY';
            mockSearchResultService.getColumns$.mockReturnValue(of(searchColumns));
            mockSearchResultService.getColumns$().subscribe((response: any) => {
                expect(response[0].title).toEqual('textColTitle');
                expect(response[1].title).toEqual('dateColTitle');
                expect(response[2].title).toEqual('hyperColTitle');
                expect(response[3].title).toEqual('imageColTitle');
            });
            c.ngOnInit();
            expect(mockSearchResultService.getColumns$).toBeCalled();
        });

        describe('Export CpaXml', () => {
            it('should call export service\'s exportToCpaXml with the right filter, when export to cpa xml option is selected', () => {
                c.filter = { prop: 'some value' };
                c.queryContextKey = 100;
                searchExportServiceMock.exportToCpaXml.mockReturnValue(of({}));
                c.cpaXmlImport();
                expect(searchExportServiceMock.exportToCpaXml).toHaveBeenCalledWith({ ...c.filter }, 100);
            });
        });

        describe('Build Groups', () => {
            it('should not build group array if there are no grouping columns', () => {
                const selectedColumns: Array<SearchResultColumn> = [{
                    id: '1',
                    title: 'a',
                    format: 'int',
                    decimalPlaces: 0,
                    currencyCodeColumnName: 'string',
                    isHyperlink: true,
                    filterable: false,
                    fieldId: 'c',
                    linkType: 'a',
                    linkArgs: [],
                    isColumnFreezed: false,
                    width: 1
                }];
                const groupArray = c.buildGroups(selectedColumns);
                expect(groupArray.length).toEqual(0);
            });
            it('should build group array if there are grouping columns', () => {
                const selectedColumns: Array<SearchResultColumn> = [{
                    id: 'a',
                    title: 'a',
                    format: 'int',
                    decimalPlaces: 0,
                    currencyCodeColumnName: 'string',
                    isHyperlink: true,
                    filterable: false,
                    fieldId: 'c',
                    linkType: 'a',
                    linkArgs: [],
                    isColumnFreezed: false,
                    groupBySortOrder: 1,
                    groupBySortDirection: 'descending',
                    width: 1
                }, {
                    id: 'b',
                    title: 'b',
                    format: 'int',
                    decimalPlaces: 0,
                    currencyCodeColumnName: 'string',
                    isHyperlink: false,
                    filterable: false,
                    fieldId: 'c',
                    linkType: 'a',
                    linkArgs: [],
                    isColumnFreezed: false,
                    groupBySortOrder: 2,
                    groupBySortDirection: 'ascending',
                    width: 1
                }, {
                    id: 'c',
                    title: 'c',
                    format: 'int',
                    decimalPlaces: 0,
                    currencyCodeColumnName: 'string',
                    isHyperlink: true,
                    filterable: false,
                    fieldId: 'c',
                    linkType: 'a',
                    linkArgs: [],
                    isColumnFreezed: false,
                    width: 1
                }];
                const groupArray = c.buildGroups(selectedColumns);
                expect(groupArray.length).toEqual(2);
                expect(groupArray[0].field).toEqual('a.value');
                expect(groupArray[0].dir).toEqual('desc');
                expect(groupArray[1].field).toEqual('b');
                expect(groupArray[1].dir).toEqual('asc');
            });
        });

        describe('Sanity check', () => {
            it('should call sanity check with selected caseIds', () => {
                c._resultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                    isAllPageSelect: false,
                    allSelectedItems: [{ caseKey: 1, selected: true }, { caseKey: 2, selected: true }],
                    rowSelection: [{ caseKey: 1, selected: true }, { caseKey: 2, selected: true }]
                });
                c._resultsGrid.getSelectedItems = jest.fn().mockReturnValue([1, 2]);
                c.createConfigurations(c.queryContextKey);
                const sanityCheck = c.actions.find(x => x.id === 'sanity-check');
                expect(sanityCheck).toBeDefined();
                sanityCheck.click(c._resultsGrid);
                expect(caseServiceMock.applySanityCheck).toHaveBeenCalledWith([1, 2]);
            });
        });

        it('should call export excel', () => {
            exportFormat = ReportExportFormat.Excel;
            c.queryParams = { skip: null, take: null, filters: [] };
            c._resultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                isAllPageSelect: false,
                allSelectedItems: [{ id: 1, text: 'database', selected: true, rowKey: '1' }, { id: 2, text: 'abc', selected: true, rowKey: '2' }, { id: 3, text: 'xyz', selected: true, rowKey: '3' }, { id: 4, text: 'pqr', selected: true, rowKey: '4' }],
                allDeSelectedItems: [],
                rowSelection: []
            });
            c.totalRecords = 4;
            c.rowKeyField = 'caseKey';
            c.filter = {
                searchRequest: [
                    {
                        anySearch: {
                            operator: 2
                        }
                    }
                ]
            };
            c.searchConfiguration = {
                allowExportFiltering: true,
                baseApiRoute: 'string',
                rowKeyField: 'string',
                pageTitle: 'string',
                hasPreview: false,
                searchType: 'string',
                imageApiKey: 'string',
                getExportObject: 'any',
                selectableSetting: 'any',
                // tslint:disable-next-line: no-empty
                customCheckboxSelection: () => { }
            };
            c.filter = { dueDateFilter: null };
            c.export(exportFormat);
            expect(searchExportServiceMock.export).toHaveBeenCalled();
        });
        it('should call export pdf', () => {
            exportFormat = ReportExportFormat.PDF;
            c.queryParams = { skip: null, take: null, filters: [] };
            c._resultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                isAllPageSelect: false,
                allSelectedItems: [{ id: 1, text: 'database', selected: true, rowKey: '1' }, { id: 2, text: 'abc', selected: true, rowKey: '2' }, { id: 3, text: 'xyz', selected: true, rowKey: '3' }, { id: 4, text: 'pqr', selected: true, rowKey: '4' }],
                allDeSelectedItems: [], rowSelection: []
            });
            c.totalRecords = 4;
            c.rowKeyField = 'caseKey';
            c.filter = {
                searchRequest: [
                    {
                        anySearch: {
                            operator: 2
                        }
                    }
                ]
            };
            c.searchConfiguration = {
                allowExportFiltering: true,
                baseApiRoute: 'string',
                rowKeyField: 'string',
                pageTitle: 'string',
                hasPreview: false,
                searchType: 'string',
                imageApiKey: 'string',
                getExportObject: 'any',
                selectableSetting: 'any',
                // tslint:disable-next-line: no-empty
                customCheckboxSelection: () => { }
            };
            c.filter = { dueDateFilter: null };
            c.export(exportFormat);
            expect(searchExportServiceMock.export).toHaveBeenCalled();
        });
        it('should call export Word', () => {
            exportFormat = ReportExportFormat.Word;
            c.queryParams = { skip: null, take: null, filters: [] };
            c._resultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                isAllPageSelect: false,
                allSelectedItems: [{ id: 1, text: 'database', selected: true, rowKey: '1' }, { id: 2, text: 'abc', selected: true, rowKey: '2' }, { id: 3, text: 'xyz', selected: true, rowKey: '3' }, { id: 4, text: 'pqr', selected: true, rowKey: '4' }],
                allDeSelectedItems: [],
                rowSelection: []
            });
            c.totalRecords = 4;
            c.rowKeyField = 'caseKey';
            c.filter = {
                searchRequest: [
                    {
                        anySearch: {
                            operator: 2
                        }
                    }
                ]
            };
            c.searchConfiguration = {
                allowExportFiltering: true,
                baseApiRoute: 'string',
                rowKeyField: 'string',
                pageTitle: 'string',
                hasPreview: false,
                searchType: 'string',
                imageApiKey: 'string',
                getExportObject: 'any',
                selectableSetting: 'any',
                // tslint:disable-next-line: no-empty
                customCheckboxSelection: () => { }
            };
            c.filter = { dueDateFilter: null };
            c.export(exportFormat);
            expect(searchExportServiceMock.export).toHaveBeenCalled();
        });

        it('should display warning if Export limit exceeded', () => {
            exportFormat = ReportExportFormat.Excel;
            c.queryParams = { skip: null, take: null, filters: [] };
            c._resultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                isAllPageSelect: false,
                allSelectedItems: [{ id: 1, text: 'database', selected: true, rowKey: '1' },
                { id: 2, text: 'abc', selected: true, rowKey: '2' },
                { id: 3, text: 'xyz', selected: true, rowKey: '3' },
                { id: 4, text: 'pqr', selected: true, rowKey: '4' },
                { id: 5, text: 'est', selected: true, rowKey: '5' },
                { id: 6, text: 'uvw', selected: true, rowKey: '6' }],
                allDeSelectedItems: [],
                rowSelection: []
            });
            c.totalRecords = 6;
            c.rowKeyField = 'caseKey';
            c.filter = {
                searchRequest: [
                    {
                        anySearch: {
                            operator: 2
                        }
                    }
                ]
            };
            c.searchConfiguration = {
                allowExportFiltering: true,
                baseApiRoute: 'string',
                rowKeyField: 'string',
                pageTitle: 'string',
                hasPreview: false,
                searchType: 'string',
                imageApiKey: 'string',
                getExportObject: 'any',
                selectableSetting: 'any',
                // tslint:disable-next-line: no-empty
                customCheckboxSelection: () => { }
            };
            c.filter = { dueDateFilter: null };
            c.export(exportFormat);
            expect(searchExportServiceMock.export).toHaveBeenCalled();
        });

        describe('Case Search TaskMenu', () => {
            it('validate initializeTaskItems', () => {
                const dataItem = {
                    caseKey: 233,
                    CaseReference: '1234/a',
                    isEditable: true
                };
                c.isHosted = false;
                const taskItems = [{
                    id: 'caseWebLinks',
                    text: 'caseTaskMenu.openCaseWebLinks',
                    icon: 'cpa-icon cpa-icon-bookmark',
                    items: []
                }];
                taskMenuProviderMock.getConfigurationTaskMenuItems = jest.fn(() => { return taskItems; });
                c.initializeTaskItems(dataItem);
                expect(c.taskItems.length).toEqual(1);
                expect(c.taskItems[0].id).toEqual('caseWebLinks');
            });

            it('should call onMenuItemSelected', () => {
                const menuItemMock = {
                    dataItem: {
                        caseKey: '233',
                        CaseReference: '1234/a',
                        isEditable: true
                    },
                    event: {
                        item:
                        {
                            action: jest.fn()
                        }
                    }
                };
                c.onMenuItemSelected(menuItemMock);
                expect(menuItemMock.event.item.action).toHaveBeenCalledWith(menuItemMock.dataItem, menuItemMock.event);
            });
        });

        describe('ngOnDestroy', () => {
            it('should disconnect bindings', () => {
                c.bgContentSubscription = { unsubscribe: jest.fn() };
                c.dwnlContentSubscription = { unsubscribe: jest.fn() };

                c.ngOnDestroy();

                expect(messageBroker.disconnectBindings).toHaveBeenCalled();
                expect(c.bgContentSubscription.unsubscribe).toHaveBeenCalled();
                expect(c.dwnlContentSubscription.unsubscribe).toHaveBeenCalled();
            });
        });

        describe('Refresh', () => {
            it('should call Refresh', () => {
                const gridOptions = {
                    _refresh: jest.fn()
                } as any;
                c.gridOptions = gridOptions;
                c.refresh();
                expect(c.gridOptions._refresh).toBeDefined();
                expect(c.gridOptions._refresh).toBeCalled();
                expect(c.isRefreshClickedInHosted).toEqual(false);
            });

            it('should call Refresh when hosted', () => {
                const gridOptions = {
                    _refresh: jest.fn()
                } as any;
                c.gridOptions = gridOptions;
                c.isHosted = true;
                c.hybridResulElementRef = { nativeElement: jest.fn() };
                c.refresh();
                expect(c.gridOptions._refresh).toBeDefined();
                expect(c.gridOptions._refresh).toBeCalled();
                expect(c.isRefreshClickedInHosted).toEqual(true);
            });
        });

        it('validate getFlagStyle with RestrictedCasesIcon', () => {
            const style = c.getFlagStyle('RestrictedCasesIcon');
            expect(style).toMatchObject({ color: '#ff0000' });
        });

        it('validate tooltip text with RestrictedCasesIcon', () => {
            const text = c.getToolTipMessage('RestrictedCasesIcon');
            expect(text).toEqual('SearchColumns.billSearch.hasRestrictedCases');
        });
    });
});