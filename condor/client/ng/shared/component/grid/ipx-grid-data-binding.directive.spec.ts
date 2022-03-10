// tslint:disable: no-unbound-method
import { EventEmitter } from '@angular/core';
import { ChangeDetectorRefMock } from 'mocks';
import { IpxKendoGroupingServiceMock } from 'mocks/ipx-kendo-grouping.service.mock';
import { of } from 'rxjs';
import { IpxGridDataBindingDirective } from './ipx-grid-data-binding.directive';
import { IpxGridOptions } from './ipx-grid-options';

describe('ipx-grid-data-binding.directive', () => {
    let directive: IpxGridDataBindingDirective;
    let grid: any;
    const ipxGroupingService = new IpxKendoGroupingServiceMock();
    const initWithData = (gridOptions: IpxGridOptions): void => {
        directive.dataOptions = gridOptions;
        directive.ngOnInit();
    };

    beforeEach(() => {
        grid = {
            dataStateChange: new EventEmitter<any>(), onDataChange: jest.fn(),
            data: {
                data: [
                    {
                        casetypedescription__6_: 'Properties',
                        propertytypedescription__8_: 'Trade Mark',
                        propertyTypeKey: 'T',
                        id: '551_1'
                    },
                    {
                        statusdescription__14_: 'Registered',
                        casetypedescription__6_: 'Properties',
                        propertytypedescription__8_: 'Trade Mark',
                        propertyTypeKey: 'T',
                        statusKey: -210,
                        id: '-487_2'
                    },
                    {
                        casetypedescription__6_: 'Properties',
                        propertytypedescription__8_: 'Trademark',
                        propertyTypeKey: 'T',
                        id: '-486_3'
                    },
                    {
                        casetypedescription__6_: 'Properties',
                        propertytypedescription__8_: 'Trade Mark',
                        propertyTypeKey: 'T',
                        id: '-485_4'
                    }
                ],
                total: 4
            }
        };
        directive = new IpxGridDataBindingDirective(grid, new ChangeDetectorRefMock() as any, ipxGroupingService as any);
        directive.dataOptions = {} as any;
        spyOn(directive.onDataBinding, 'emit');

    });

    it('calls search automatically if autobind is set', () => {
        const options = { autobind: true, read$: jest.fn(() => of([])) } as any;
        initWithData(options);
        expect(options.read$).toHaveBeenCalled();
    });

    it('emits databinding event', () => {
        const options = { read$: jest.fn(() => of([{ id: 'id', code: 'code' }])) } as any;
        initWithData(options);

        expect(options.read$).not.toHaveBeenCalled();

        directive.rebind();
        expect(options.read$).toHaveBeenCalled();
        expect(directive.onDataBinding.emit).toHaveBeenCalled();
    });

    it('handles data in array format', () => {
        const data = [
            { id: 'id1', code: 'code1' },
            { id: 'id2', code: 'code2' }
        ];
        const options = { autobind: true, read$: jest.fn(() => of(data)) } as any;
        initWithData(options);

        expect(grid.data).toEqual(data);
    });

    it('clear data', () => {
        const data = [
            { id: 'id1', code: 'code1' },
            { id: 'id2', code: 'code2' }
        ];
        const options = { autobind: true, read$: jest.fn(() => of(data)) } as any;
        initWithData(options);

        directive.clear();
        expect(grid.data).toEqual([]);
    });

    it('clear state to Refresh Grid ', () => {
        directive.refreshGrid = jest.fn();
        directive.refreshGrid();
        expect(directive.refreshGrid).toHaveBeenCalled();
    });

    it('transforms data from paging format to the kendo grid paging format', () => {
        const data = {
            data: [
                { id: 'id1', code: 'code1' },
                { id: 'id2', code: 'code2' }
            ],
            pagination: { total: 2 }
        };
        const options = { autobind: true, read$: jest.fn(() => of(data)) } as any;
        initWithData(options);

        expect(grid.data).toEqual({
            data: data.data,
            total: 2
        });
    });

    describe('filters, pagination and sorting', () => {
        let options;
        beforeEach(() => {
            options = { read$: jest.fn(() => of([])) } as any;
            initWithData(options);
        });

        it('only uses first sorting state', () => {
            (directive as any).state.sort = [{ field: 'first', dir: 'desc' }, { field: 'second', dir: 'asc' }];
            directive.rebind();

            expect(options.read$).toHaveBeenCalledWith(expect.objectContaining({ sortBy: 'first', sortDir: 'desc' }));
        });

        it('sorting is removed if no direction defined, i.e. 3 clicks', () => {
            (directive as any).state.sort = [{ field: 'first' }];
            directive.rebind();

            expect(options.read$).toHaveBeenCalledWith(expect.objectContaining({ sortBy: undefined, sortDir: undefined }));
        });

        it('calling select page loads the data by setting correct skip', () => {
            directive.selectPage(10);

            expect(options.read$).toHaveBeenCalledWith(expect.objectContaining({ skip: 10 }));
        });

        it('resets paging to first page if sorting is changed', () => {
            grid.skip = 20;
            (directive as any).state = {
                skip: 20,
                sort: [{ field: 'first', dir: 'desc' }]
            };

            directive.rebind();

            expect(options.read$).toHaveBeenCalledWith(expect.objectContaining({ skip: 0, sortBy: 'first', sortDir: 'desc' }));
            expect(grid.skip).toBe(0);

            directive.selectPage(20);
            expect(options.read$).toHaveBeenCalledWith(expect.objectContaining({ skip: 20, sortBy: 'first', sortDir: 'desc' }));

            (directive as any).state.sort = [{ field: 'first' }];
            directive.rebind();
            expect(options.read$).toHaveBeenCalledWith(expect.objectContaining({ skip: 0, sortBy: undefined, sortDir: undefined }));
        });

        it('sends correct filters', () => {
            (directive as any).state.filter = { logic: 'and', filters: [{ logic: 'and', filters: [{ field: 'first', operator: 'eq', value: '123' }] }] };
            directive.rebind();

            expect(options.read$).toHaveBeenCalledWith(expect.objectContaining({ filters: [{ field: 'first', operator: 'eq', value: '123' }] }));
        });

        it('correctly transforms multiple kendo grid filters to inprotech filters', () => {
            (directive as any).state.filter = {
                logic: 'and', filters: [
                    { logic: 'and', filters: [{ field: 'first', operator: 'eq', value: '123' }] },
                    { logic: 'and', filters: [{ field: 'second', operator: 'eq', value: 'abc' }] }
                ]
            };
            directive.rebind();

            expect(options.read$).toHaveBeenCalledWith(expect.objectContaining({
                filters: [{ field: 'first', operator: 'eq', value: '123' },
                { field: 'second', operator: 'eq', value: 'abc' }]
            }));
        });

    });

    describe('manual operations grid', () => {
        it('it auto binds if autobind is set', () => {
            const options = { manualOperations: true, autobind: true, read$: jest.fn(() => of([])) } as any;
            initWithData(options);
            expect(options.read$).toHaveBeenCalled();
        });

        it('it binds data if oneTimebind is called', () => {
            const options = { manualOperations: true, autobind: false, read$: jest.fn(() => of([])) } as any;
            initWithData(options);
            expect(options.read$).not.toHaveBeenCalled();

            directive.bindOneTimeData();
            expect(options.read$).toHaveBeenCalled();
        });

        it('it does not call read on rebind', () => {
            const options = { manualOperations: true, autobind: false, read$: jest.fn(() => of([])) } as any;
            initWithData(options);
            directive.rebind();

            expect(options.read$).not.toHaveBeenCalled();
        });
    });
    it('applies grouping correctly', () => {
        directive.dataOptions.groups = [{ field: 'propertytypedescription__8_' }];
        jest.spyOn(ipxGroupingService, 'convertRecordForGrouping');

        directive.applyGrouping();
        expect(grid.data).not.toBe(null);
        expect(grid.data.data.length).toEqual(2);
        expect(grid.data.total).toEqual(4);
    });
});