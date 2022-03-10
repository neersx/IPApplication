import { TestBed } from '@angular/core/testing';
import { PageHelperService } from './page-helper.service';

describe('Page Helper service', () => {
  let pageHelper: PageHelperService;

  beforeEach(() => {
      TestBed.configureTestingModule({
        providers: [
            PageHelperService
        ]
      });
      pageHelper = TestBed.get(PageHelperService);
    });

    it('should return index of id on page', () => {
        const ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        const id = 5;
        const pageSize = 10;

        let result = pageHelper.getPageForId(ids, id, pageSize);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(4);

        result = pageHelper.getPageForId(ids, 99, pageSize);
        expect(result.page).toEqual(-1);
        expect(result.relativeRowIndex).toEqual(-1);
    });

    it('should return page and relative index of an id', () => {
        const ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
        const id = 13;
        const pageSize = 10;
        let result = pageHelper.getPageForId(ids, id, pageSize);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(2);

        result = pageHelper.getPageForId(ids, 1, 10);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(0);

        result = pageHelper.getPageForId(ids, 10, 10);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(9);

        result = pageHelper.getPageForId(ids, 11, 10);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(0);

        result = pageHelper.getPageForId(ids, 99, 10);
        expect(result.page).toEqual(-1);
        expect(result.relativeRowIndex).toEqual(-1);
    });

    it('should handle string ids', () => {
        const ids = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];

        let result = pageHelper.getPageForId(ids, 'A', 5);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(0);

        result = pageHelper.getPageForId(ids, 'E', 5);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(4);

        result = pageHelper.getPageForId(ids, 'F', 5);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(0);

        result = pageHelper.getPageForId(ids, 'G', 5);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(1);

        result = pageHelper.getPageForId(ids, 'J', 5);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(4);

        result = pageHelper.getPageForId(ids, 'N', 5);
        expect(result.page).toEqual(3);
        expect(result.relativeRowIndex).toEqual(3);

        result = pageHelper.getPageForId(ids, 'Z', 5);
        expect(result.page).toEqual(-1);
        expect(result.relativeRowIndex).toEqual(-1);
    });
});
