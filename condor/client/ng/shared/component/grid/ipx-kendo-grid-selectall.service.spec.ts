import { IPXKendoGridSelectAllService } from './ipx-kendo-grid-selectall.service';
describe('SelectAllService', () => {
    let service: IPXKendoGridSelectAllService;
    let data = {};
    beforeEach(() => {
        service = new IPXKendoGridSelectAllService();
        data = [{ id: 1, text: 'database', selected: true, rowKey: '1' }, { id: 2, text: 'abc', selected: true, rowKey: '2' }, { id: 3, text: 'xyz', selected: true, rowKey: '3' }, { id: 4, text: 'pqr', selected: true, rowKey: '4' }];
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });
    it('should return selected id indivisualy when paging is true', () => {
        const deselectedIds = ['1'];
        const selectedIds = [];
        const allDeSelectIds = [];
        const allDeSelectedItems = [];
        const countOfRecord = ['1', '2', '3', '4'];
        const rowkey = 'rowKey';
        const isPagingEnabled = true;
        const result = service.manageSelectDeSelect(deselectedIds, selectedIds, allDeSelectIds, allDeSelectedItems, countOfRecord, data, rowkey, isPagingEnabled);
        expect(result.allDeSelectedItems).toEqual([data[0]]);
        expect(result.allDeSelectIds).toEqual(['1']);
        expect(result.countOfRecord).toEqual(['2', '3', '4']);
    });

    it('should return selected id individually when paging is false', () => {
        const deselectedIds = ['1'];
        const selectedIds = [];
        const allDeSelectIds = [];
        const allDeSelectedItems = [];
        const countOfRecord = ['1', '2', '3', '4'];
        const rowkey = 'rowKey';
        const isPagingEnabled = false;
        const result = service.manageSelectDeSelect(deselectedIds, selectedIds, allDeSelectIds, allDeSelectedItems, countOfRecord, data, rowkey, isPagingEnabled);
        expect(result.allDeSelectedItems).toEqual([data[0]]);
        expect(result.allDeSelectIds).toEqual(['1']);
        expect(result.countOfRecord).toEqual(['1', '2', '3', '4']);
    });
    it(' should return deselectID and no. of selected record  when paging is true', () => {
        const deselectedIds = ['1', '2'];
        const selectedIds = ['3', '4'];
        const allDeSelectIds = ['1'];
        const allDeSelectedItems = [data[0]];
        const countOfRecord = ['1', '2', '3', '4'];
        const rowkey = 'rowKey';
        const isPagingEnabled = true;
        const result = service.manageSelectDeSelect(deselectedIds, selectedIds, allDeSelectIds, allDeSelectedItems, countOfRecord, data, rowkey, isPagingEnabled);
        expect(result.allDeSelectedItems).toEqual([data[0], data[1]]);
        expect(result.allDeSelectIds).toEqual(['1', '2']);
        expect(result.countOfRecord.length).toEqual(3);
    });

    it(' should return deselectID and no. of selected record  when paging is false', () => {
        const deselectedIds = ['4'];
        const selectedIds = ['3', '4'];
        const allDeSelectIds = ['1'];
        const allDeSelectedItems = [data[0]];
        const countOfRecord = ['1', '2', '3', '4'];
        const rowkey = 'rowKey';
        const isPagingEnabled = false;
        const result = service.manageSelectDeSelect(deselectedIds, selectedIds, allDeSelectIds, allDeSelectedItems, countOfRecord, data, rowkey, isPagingEnabled);
        expect(result.allDeSelectedItems).toEqual([data[0]]);
        expect(result.allDeSelectIds).toEqual(['1']);
        expect(result.countOfRecord.length).toEqual(4);
    });

    it('set all deselected id', () => {
        const deselectedIds = '1';
        const allDeSelectedItems = [];
        const rowkey = 'rowKey';
        service.setAllDeSelectedItem({ items: data }, deselectedIds, rowkey, allDeSelectedItems);
        expect(allDeSelectedItems).toEqual([data[0]]);
    });

    it('should reduce count of records on de-selection - even while working with rowSelectionKey different than rowKey', () => {
        const input = [{ id: 1, text: 'database', selected: true, rowKey: '1', caseKey: 'key11' },
        { id: 2, text: 'abc', selected: true, rowKey: '2', caseKey: 'key12' },
        { id: 3, text: 'xyz', selected: true, rowKey: '3', caseKey: 'key13' },
        { id: 4, text: 'pqr', selected: true, rowKey: '4', caseKey: 'key14' }];
        const deselectedIds = ['key11', 'key13'];
        const selectedIds = ['3', '4'];
        const allDeSelectIds = ['key11'];
        const allDeSelectedItems = [data[0]];
        const countOfRecord = ['1', '2', '3' ];
        const rowkey = 'caseKey';
        const isPagingEnabled = true;
        const result = service.manageSelectDeSelect(deselectedIds, selectedIds, allDeSelectIds, allDeSelectedItems, countOfRecord, input, rowkey, isPagingEnabled);
        expect(result.countOfRecord.length).toEqual(2);
        expect(result.countOfRecord).not.toContain('1');
    });

    it('should add a entry to count of records on re-selection - even while working with rowSelectionKey different than rowKey', () => {
        const input = [{ id: 1, text: 'database', selected: true, rowKey: '1', caseKey: 'key11' },
        { id: 2, text: 'abc', selected: true, rowKey: '2', caseKey: 'key12' },
        { id: 3, text: 'xyz', selected: true, rowKey: '3', caseKey: 'key13' },
        { id: 4, text: 'pqr', selected: true, rowKey: '4', caseKey: 'key14' }];
        const deselectedIds = ['key11'];
        const selectedIds = ['key13'];
        const allDeSelectIds = ['key11', 'key13'];
        const allDeSelectedItems = [data[0], data[2]];
        const countOfRecord = ['1', '2', '3' ];
        const rowkey = 'caseKey';
        const isPagingEnabled = true;
        const result = service.manageSelectDeSelect(deselectedIds, selectedIds, allDeSelectIds, allDeSelectedItems, countOfRecord, input, rowkey, isPagingEnabled);
        expect(result.countOfRecord.length).toEqual(4);
        expect(result.countOfRecord).toContain('key13');
    });
});
