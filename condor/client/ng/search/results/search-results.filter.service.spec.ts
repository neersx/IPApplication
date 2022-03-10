
import { CaseSerachResultFilterService } from './search-results.filter.service';
describe('FilterService', () => {
    let service: CaseSerachResultFilterService;
    beforeEach(() => {
        service = new CaseSerachResultFilterService();
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });

    it('should return the filter when we have allselect with deselect Ids', () => {
        const isAllPageSelect = true;
        const allSelectedItems = [];
        const allDeSelectedItems = [{ id: 1, text: 'database', selected: false, rowKey: '1' }, { id: 2, text: 'abc', selected: false, rowKey: '2' }, { id: 3, text: 'xyz', selected: false, rowKey: '3' }, { id: 4, text: 'pqr', selected: false, rowKey: '4' }];
        const filterdata = {
            searchRequest: [
                {
                    anySearch: {
                        operator: 2
                    }
                }
            ]
        };
        const result = service.getFilter(isAllPageSelect, allSelectedItems, allDeSelectedItems, 'id', filterdata, '');

        expect(result.deselectedIds.length).toEqual(4);
        expect(result.searchRequest.length).toEqual(1);
    });

    it('should return the filter when we have select Ids only', () => {
        const isAllPageSelect = false;
        const allDeSelectedItems = [];
        const allSelectedItems = [{ id: 1, text: 'database', selected: true, rowKey: '1' }, { id: 2, text: 'abc', selected: true, rowKey: '2' }, { id: 3, text: 'xyz', selected: true, rowKey: '3' }, { id: 4, text: 'pqr', selected: true, rowKey: '4' }];
        const filterdata = {
            searchRequest: [
                {
                    anySearch: {
                        operator: 2
                    }
                }
            ]
        };
        const searchConfig = { getExportObject: jest.fn() };
        const caseIds = ['1', '2', '3', '4'];
        spyOn(searchConfig, 'getExportObject').and.returnValue(caseIds);
        const result = service.getFilter(isAllPageSelect, allSelectedItems, allDeSelectedItems, 'id', filterdata, searchConfig);
        expect(result.searchRequest[0]).toEqual(caseIds);
    });

    it('should return the filter when we dont have select or deselect Ids only', () => {
        const isAllPageSelect = false;
        const allDeSelectedItems = [];
        const allSelectedItems = [];
        const filterdata = {
            searchRequest: [
                {
                    anySearch: {
                        operator: 2
                    }
                }
            ]
        };
        const result = service.getFilter(isAllPageSelect, allSelectedItems, allDeSelectedItems, 'id', filterdata, '');
        expect(result.searchRequest).toEqual([
            {
                anySearch: {
                    operator: 2
                }
            }
        ]);
        expect(result.deselectedIds).toEqual([]);
    });

});
