import { BehaviorSubjectMock } from 'mocks';
import { Observable } from 'rxjs';

export class TaxCodeMock {
    runSearch = jest.fn().mockReturnValue(new Observable());
    _previousStateParam$ = new BehaviorSubjectMock();
    _taxCodeDescription$ = new BehaviorSubjectMock();
    overviewDetails = jest.fn().mockReturnValue(new Observable());
    ids = [1, 2];
    deleteTaxCodes = jest.fn().mockReturnValue(new Observable());
    inUseTaxCode = [1, 2];
    updateTaxCodeDetails = jest.fn().mockReturnValue(new Observable());
    saveTaxCode = jest.fn().mockReturnValue(new Observable());
}