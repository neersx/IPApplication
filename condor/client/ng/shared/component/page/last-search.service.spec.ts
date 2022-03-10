import { TestBed } from '@angular/core/testing';
import { noop } from 'rxjs';
import { LastSearchService } from './last-search.service';
import { PageHelperService } from './page-helper.service';

describe('Page Helper service', () => {
    let pageHelper: PageHelperService;
    let lastSearch: LastSearchService;

    beforeEach(() => {
        const pageHelperSpy = { getPageForId: jest.fn() };
        TestBed.configureTestingModule({
            providers: [
                LastSearchService,
                { provide: PageHelperService, useValue: pageHelperSpy }
            ]
        });
        pageHelper = TestBed.get(PageHelperService);
        lastSearch = TestBed.get(LastSearchService);

        pageHelperSpy.getPageForId.mockReturnValue({ page: 1, relativeRowIndex: 1 });
    });
    it('can set ids', () => {
        const ids = [1, 2];
        lastSearch.setInitialData({
            method: noop,
            methodName: 'a',
            args: []
        });
        lastSearch.setAllIds(ids);
        expect(lastSearch.ids).toEqual(ids);
    });

    it('can get previous defined ids', () => {
        const ids = [1, 2];
        lastSearch.setInitialData({
            method: noop,
            methodName: 'a',
            args: []
        });
        lastSearch.setAllIds(ids);
        lastSearch.getAllIds()
            .then((data) => { expect(data).toEqual(ids); })
            .catch(() => 'error');
    });

    it('should run previous search', () => {
        const ids = [1, 2];
        lastSearch.setInitialData({
            method: () => new Promise<any>((resolve) => { resolve(ids); }),
            methodName: 'a',
            args: [{}]
        });
        lastSearch.getAllIds()
            .then((data) => { expect(data).toEqual(ids); })
            .catch(() => 'error');
    });

    it('can get the current page size', () => {
        lastSearch.setInitialData({
            method: noop,
            methodName: 'a',
            args: [{}, {
                take: 123
            }]
        });
        const result = lastSearch.getPageSize();
        expect(result).toBe(123);
    });
    describe('Get Page For Id Method', () => {
        it('returns call to pager helper service with the right parameters', () => {
            lastSearch.setInitialData({
                method: noop,
                methodName: 'a',
                args: [{}, {
                    take: 99
                }]
            });
            const ids = [1];
            lastSearch.setAllIds(ids);
            const result = lastSearch.getPageForId(123);

            expect(pageHelper.getPageForId).toHaveBeenCalledWith(ids, 123, 99);
            expect(result).toEqual({ page: 1, relativeRowIndex: 1 });
        });
    });
});
