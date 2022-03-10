import { LocalSettings } from 'core/local-settings';
import { SearchOperator } from './search-operators';

export class SearchTypeConfig {
    baseApiRoute: string;
    rowKeyField: string;
    pageTitle: string;
    hasPreview: boolean;
    searchType: string;
    imageApiKey: string;
    getExportObject: any;
    selectableSetting: any;
    allowExportFiltering: boolean;
    customCheckboxSelection: (dataItem: any, data: Array<any>) => void;
}

export enum queryContextKeyEnum {
    caseSearch = 2,
    caseSearchExternal = 1,
    nameSearch = 10,
    nameSearchExternal = 15,
    wipOverview = 200,
    priorArtSearch = 900,
    caseFeeSearchInternal = 331,
    caseFeeSearchExternal = 330,
    caseInstructionSearchInternal = 340,
    caseInstructionSearchExternal = 341,
    reciprocitySearch = 18,
    adHocDateSearch = 164,
    clientRequestSearchInternal = 198,
    clientRequestSearchExternal = 199,
    staffRemindersSearchColumns = 165,
    toDoSearchColumns = 162,
    whatsDueSearchColumns = 160,
    workHistorySearchColumns = 205,
    activitySearchColumns = 190,
    taskPlannerSearch = 970,
    roleSearch = 115,
    billSearch = 451
}

export class SearchTypeConfigProvider {
    static savedConfig: SearchTypeConfig;
    static getConfigurationConstants(queryContextKey: Number): SearchTypeConfig {
        let pageTitle = 'pageTitle';
        let rowKeyField = 'caseKey';
        let searchType = 'case';

        let hasPreview = false;
        let baseApiRoute = 'api/search/case/';
        let imageApiKey = '';
        let getExportObject: any;
        let allowExportFiltering = true;
        const selectableSetting = {
            mode: 'multiple'
        };
        let customCheckboxSelection;

        switch (queryContextKey) {
            case queryContextKeyEnum.nameSearch:
            case queryContextKeyEnum.nameSearchExternal:
                hasPreview = queryContextKey === queryContextKeyEnum.nameSearch;
                rowKeyField = 'nameKey';
                baseApiRoute = 'api/search/name/';
                pageTitle = 'nameSearchResults.pageTitle';
                searchType = 'name';
                imageApiKey = 'name';
                customCheckboxSelection = (dataItem: any, data: Array<any>) => {
                    if (dataItem) {
                        data.filter(d => d.nameKey === dataItem.nameKey).forEach(d => d.selected = dataItem.selected);
                    }
                };
                getExportObject = (ids: string) => {

                    return {
                        nameKeys: {
                            operator: 0,
                            value: ids
                        }
                    };

                };
                break;
            case queryContextKeyEnum.caseSearch:
            case queryContextKeyEnum.caseSearchExternal:
                hasPreview = true;
                rowKeyField = 'caseKey';
                baseApiRoute = 'api/search/case/';
                pageTitle = 'caseSearchResults.pageTitle';
                searchType = 'case';
                imageApiKey = 'case';
                getExportObject = (selectedIds: string) => {

                    return {
                        caseKeys: {
                            operator: 0,
                            value: selectedIds
                        }
                    };
                };
                break;
            case queryContextKeyEnum.wipOverview:
                hasPreview = false;
                rowKeyField = 'rowKey';
                baseApiRoute = 'api/search/wipOverview/';
                pageTitle = 'wipOverviewSearchResults.pageTitle';
                searchType = 'wipOverview';
                allowExportFiltering = true;
                getExportObject = (ids: string) => {
                    return {
                        rowKeys: {
                            operator: 0,
                            value: ids
                        }
                    };
                };
                break;
            case queryContextKeyEnum.priorArtSearch:
                hasPreview = false;
                rowKeyField = 'priorArtKey';
                baseApiRoute = 'api/search/priorart/';
                pageTitle = 'priorartSearchResults.pageTitle';
                searchType = 'priorart';
                allowExportFiltering = true;
                getExportObject = (ids: string) => {

                    return {
                        priorArtKeys: {
                            value: ids,
                            Operator: 0
                        }
                    };
                };
                break;
            case queryContextKeyEnum.billSearch:
                hasPreview = false;
                rowKeyField = 'rowKey';
                baseApiRoute = 'api/search/billing/';
                searchType = 'billSearch';
                pageTitle = 'billingSelectionSearchResults.pageTitle';
                allowExportFiltering = true;
                getExportObject = (ids: string) => {

                    return {
                        rowKeys: {
                            value: ids,
                            Operator: 0
                        }
                    };
                };
                break;
            case queryContextKeyEnum.taskPlannerSearch:
                rowKeyField = 'rowKey';
                baseApiRoute = 'api/taskplanner/';
                searchType = 'taskplanner';
                getExportObject = (ids: string) => {

                    return {
                        rowKeys: {
                            value: ids,
                            Operator: 0
                        }
                    };
                };
                break;
            default:
                pageTitle = 'caseSearchResults.pageTitle';
                break;

        }

        SearchTypeConfigProvider.savedConfig = {
            pageTitle,
            rowKeyField,
            hasPreview,
            baseApiRoute,
            searchType,
            imageApiKey,
            getExportObject,
            selectableSetting,
            allowExportFiltering,
            customCheckboxSelection
        };

        return SearchTypeConfigProvider.savedConfig;
    }
}
