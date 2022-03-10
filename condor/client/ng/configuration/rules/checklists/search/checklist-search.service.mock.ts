import { of } from 'rxjs';

export class ChecklistSearchServiceMock {
    getCriteriaSearchViewData$ = jest.fn().mockReturnValue(of({}));
    setSearchData = jest.fn().mockReturnValue(of({}));
    getCaseCharacteristics$ = jest.fn().mockReturnValue(of({}));
}
