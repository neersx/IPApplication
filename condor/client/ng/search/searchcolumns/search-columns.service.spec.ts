import { GridNavigationServiceMock } from 'mocks';
import { of } from 'rxjs';
import * as _ from 'underscore';
import { QueryColumnViewData, SearchColumnSaveDetails } from './search-columns.model';
import { SearchColumnsService } from './search-columns.service';
describe('SearchColumnsService', () => {
    let service: SearchColumnsService;
    let httpClientSpy: any;
    let gridNavigationService: GridNavigationServiceMock;
    const queryViewData: QueryColumnViewData = { queryContextPermissions: [], queryContextKey: 1 };
    beforeEach(() => {
        httpClientSpy = { get: jest.fn().mockReturnValue({
            pipe: (args: any) => {
                return [];
            }
        }), post: jest.fn(), put: jest.fn() };
        gridNavigationService = new GridNavigationServiceMock();
        service = new SearchColumnsService(httpClientSpy, gridNavigationService as any);
    });
    it('should call the getColumnsViewData method', () => {
        const params = { queryContextKey: 1 };
        httpClientSpy.get.mockReturnValue(of(queryViewData));
        service.getColumnsViewData(params).subscribe(result => {
            expect(result).toBeTruthy();
            expect(result.queryContextKey).toEqual(1);
        });
    });

    it('should call the getSearchColumns method', () => {
        const searchCriteria = {
            text: '',
            queryContextKey: 1
        };
        const params = { queryContextKey: 1 };
        jest.spyOn(gridNavigationService, 'init');

        service.getSearchColumns(searchCriteria, params);

        expect(gridNavigationService.setNavigationData).toHaveBeenCalled();
        expect(httpClientSpy.get).toHaveBeenCalledWith('api/search/columns/search', {
            params: {
                searchOption: JSON.stringify(searchCriteria),
                queryParams: JSON.stringify(params)
            }
        });
    });

    it('should call the searchColumnUsage method', () => {
        const columnKey = 1;
        httpClientSpy.get.mockReturnValue(of([]));
        service.searchColumnUsage(columnKey).subscribe(result => {
            expect(result).toBeTruthy();
            expect(result).toEqual([]);
        });
    });

    it('should call the searchColumn method', () => {
        const queryContextKey = 1;
        const columnKey = 1;
        httpClientSpy.get.mockReturnValue(of(SearchColumnSaveDetails));
        service.searchColumn(columnKey, queryContextKey).subscribe(result => {
            expect(result).toBeTruthy();
            expect(result).toEqual([]);
        });
    });

    it('should call the saveSearchColumn method', () => {
        const request = {
            isMandatory: true,
            isVisible: true,
            isInternal: true,
            isExternal: false,
            parameter: null,
            docItem: null,
            dataFormat: 'String',
            displayName: 'hhhh',
            columnName: {
                key: 739,
                description: 'ChargeDueEventAny',
                queryContext: 2,
                isQualifierAvailable: false,
                isUserDefined: false,
                dataFormat: 'String',
                isUsedBySystem: false
            },
            internalQueryContext: 2,
            externalQueryContext: null
        };
        httpClientSpy.post.mockReturnValue(of({
            result: 'success',
            updatedId: 279
        }));
        service.saveSearchColumn(request).subscribe(result => {
            expect(result).toBeTruthy();
            expect(result).toEqual({
                result: 'success',
                updatedId: 279
            });
        });
    });

    it('should call the updateSearchColumn method', () => {
        const request = {
            columnId: -19,
            displayName: 'Abstract',
            columnName: {
                key: 57,
                description: 'Text',
                queryContext: 2,
                isQualifierAvailable: true,
                isUserDefined: false,
                dataFormat: 'Formatted Text',
                isUsedBySystem: false
            },
            parameter: 'A',
            docItem: null,
            description: 'The abstract text for the case.hd',
            isMandatory: false,
            isVisible: true,
            dataFormat: 'Formatted Text',
            columnGroup: {
                key: -13,
                value: 'Additional Informationcf',
                contextId: 2
            },
            isInternal: true,
            isExternal: false,
            internalQueryContext: 2,
            externalQueryContext: null
        };
        httpClientSpy.put.mockReturnValue(of({
            result: 'success',
            updatedId: -19
        }));
        service.updateSearchColumn(request).subscribe(result => {
            expect(result).toBeTruthy();
            expect(result).toEqual({
                result: 'success',
                updatedId: -19
            });
        });
    });

    it('should call the deleteSearchColumns method', () => {
        const ids = [-19, 15];
        const contextId = 2;
        httpClientSpy.post.mockReturnValue(of({
            inUseIds: [
                15
            ],
            hasError: true,
            message: 'Items highlighted in red cannot be deleted as they are in use.'
        }));
        service.deleteSearchColumns(ids, contextId).subscribe(result => {
            expect(result).toBeTruthy();
            expect(result).toEqual({
                inUseIds: [
                    15
                ],
                hasError: true,
                message: 'Items highlighted in red cannot be deleted as they are in use.'
            });
        });
    });

    it('should call the persistSavedSearchColumns method', () => {
        const data = [
            {
                dataItemId: 51,
                contextId: 2,
                displayName: 'Acceptance Date',
                columnNameDescription: 'The date the case was accepted',
                columnId: 15
            },
            {
                dataItemId: 31,
                contextId: 2,
                displayName: 'Agent',
                columnNameDescription: 'The name of the Agent.',
                columnId: -92
            },
            {
                dataItemId: 35,
                contextId: 2,
                displayName: 'Agent Attention',
                columnNameDescription: 'The attention name for the Agent of the case.',
                columnId: -94
            },
            {
                dataItemId: 33,
                contextId: 2,
                displayName: 'Agent Code',
                columnNameDescription: 'The identifying name code for the Agent of the case.',
                columnId: -93
            },
            {
                dataItemId: 32,
                contextId: 2,
                displayName: 'Agent Details',
                columnNameDescription: 'The name and address of the Agent for the case.',
                columnId: -95
            },
            {
                dataItemId: 38,
                contextId: 2,
                displayName: 'Agents Reference',
                columnNameDescription: 'The Agents identifying reference for the case.',
                columnId: 96
            },
            {
                dataItemId: 197,
                contextId: 2,
                displayName: 'All Dates Cycle',
                columnNameDescription: 'The cycle number of each of the Events',
                columnId: 2
            },
            {
                dataItemId: 198,
                contextId: 2,
                displayName: 'All Dates Description',
                columnNameDescription: 'The description of each of the Events',
                columnId: 3
            },
            {
                dataItemId: 199,
                contextId: 2,
                displayName: 'All Dates Due',
                columnNameDescription: 'A list of the due dates associated with Events',
                columnId: 4
            }
        ];
        service.savedSearchColumns = [-19,
            15,
            15];
        service.persistSavedSearchColumns(data);
        let filterset: any;
        filterset = _.first(data.filter(x => x.columnId === 15));
        expect(filterset.persisted).toEqual(true);
    });

    it('should call the markInUseSearchColumns method', () => {
        const data = [
            {
                dataItemId: 51,
                contextId: 2,
                displayName: 'Acceptance Date',
                columnNameDescription: 'The date the case was accepted',
                columnId: 15
            },
            {
                dataItemId: 31,
                contextId: 2,
                displayName: 'Agent',
                columnNameDescription: 'The name of the Agent.',
                columnId: -92
            },
            {
                dataItemId: 35,
                contextId: 2,
                displayName: 'Agent Attention',
                columnNameDescription: 'The attention name for the Agent of the case.',
                columnId: -94
            },
            {
                dataItemId: 33,
                contextId: 2,
                displayName: 'Agent Code',
                columnNameDescription: 'The identifying name code for the Agent of the case.',
                columnId: -93
            },
            {
                dataItemId: 32,
                contextId: 2,
                displayName: 'Agent Details',
                columnNameDescription: 'The name and address of the Agent for the case.',
                columnId: -95
            },
            {
                dataItemId: 38,
                contextId: 2,
                displayName: 'Agents Reference',
                columnNameDescription: 'The Agents identifying reference for the case.',
                columnId: 96
            },
            {
                dataItemId: 197,
                contextId: 2,
                displayName: 'All Dates Cycle',
                columnNameDescription: 'The cycle number of each of the Events',
                columnId: 2
            },
            {
                dataItemId: 198,
                contextId: 2,
                displayName: 'All Dates Description',
                columnNameDescription: 'The description of each of the Events',
                columnId: 3
            },
            {
                dataItemId: 199,
                contextId: 2,
                displayName: 'All Dates Due',
                columnNameDescription: 'A list of the due dates associated with Events',
                columnId: 4
            }
        ];
        service.inUseSearchColumns = [-19,
            15,
            15];
        service.markInUseSearchColumns(data);
        let filterset: any;
        filterset = _.first(data.filter(x => x.columnId === 15));
        expect(filterset.persisted).toEqual(false);
        expect(filterset.inUse).toEqual(true);
        expect(filterset.selected).toEqual(true);
    });
});