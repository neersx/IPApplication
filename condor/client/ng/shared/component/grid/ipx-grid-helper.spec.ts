import { GridHelper } from './ipx-grid-helper';

describe('Angular Kendo Grid Helper', () => {
    let gridHelper: GridHelper;
    beforeEach(() => {
        gridHelper = new GridHelper();
    });

    describe('anyColumnLocked', () => {
        it('anyColumnLocked should be return false if all columns are locked', () => {
            const gridOptions = {
                filterable: true,
                sortable: false,
                reorderable: true,
                canAdd: true,
                noResultsFoundMessage: 'No',
                columns: [
                    { field: 'field1', fixed: true, locked: true },
                    { field: 'field1', fixed: true, locked: true }
                ]
            } as any;

            expect(gridHelper.isAnyColumnLokced(gridOptions)).toBeFalsy();
        });

        it('anyColumnLocked should be return true if any of the columns are locked', () => {
            const gridOptions = {
                filterable: true,
                sortable: false,
                reorderable: true,
                canAdd: true,
                noResultsFoundMessage: 'No',
                columns: [
                    { field: 'field1', fixed: true, locked: true },
                    { field: 'field1', fixed: true, locked: false }
                ]
            } as any;

            expect(gridHelper.isAnyColumnLokced(gridOptions)).toBeTruthy();
        });
    });

    describe('toClassList', () => {
        it('should return class list array', () => {
            const classString = 'class1 class2 class3';
            const data = gridHelper.toClassList(classString);

            expect(data.length).toEqual(3);
            expect(data[0]).toEqual('class1');
        });
    });

    describe('storePageSizeToLocalStorage', () => {
        it('sets local storage and set page size from local storage', () => {
            const pageLocalSettings = { getLocal: 15, setLocal: jest.fn() };

            const pageData = gridHelper.storePageSizeToLocalStorage(5, pageLocalSettings);
            expect(pageData.oldPagesize).toEqual(15);
        });
    });

    describe('setColumnsPreference', () => {
        it('set kendo grid column preferences', () => {
            const columns = [
                { field: 'field0', title: '', fixed: true },
                { field: 'field1', title: 'field-1', fixed: true },
                { field: 'field2', title: 'field-2' },
                { field: 'field3', title: 'field-3', hidden: true },
                { field: 'field4', title: 'field-4' }
            ];

            const stored = [
                { field: 'field1', title: 'field-1', index: 0 },
                { field: 'field4', title: 'field-4', index: 1 },
                { field: 'field3', title: 'field-3', hidden: true, index: 2 },
                { field: 'field2', title: 'field-2', index: 3 }
            ];

            const gridOptions = {
                filterable: true,
                sortable: false,
                reorderable: true,
                canAdd: true,
                noResultsFoundMessage: 'No',
                columns,
                columnSelection: {
                    localSetting: {
                        getLocal: stored,
                        setLocal: jest.fn()
                    }
                }
            } as any;

            gridHelper.setColumnsPreference(gridOptions);
            expect(gridOptions.columns[0].fixed).toBeTruthy();
            expect(gridOptions.columns[0].title).toEqual('');
        });
    });
});