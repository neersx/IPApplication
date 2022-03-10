import { of } from 'rxjs';
import { CurrencyItems } from './currencies.model';

export class CurrenciesServiceMock {
    private readonly testResponse = new CurrencyItems();
    getCurrencies = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    getViewData = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    deleteCurrencies = jest.fn().mockReturnValue(of({ result: 'success' }));
    getCurrencyDesc = jest.fn().mockReturnValue(of('AUD'));
}