import { GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { CurrencyRequest } from './currencies.model';
import { CurrenciesService } from './currencies.service';
describe('CurrencService', () => {

    let service: CurrenciesService;
    let httpMock: HttpClientMock;
    let gridNavigationService: GridNavigationServiceMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        gridNavigationService = new GridNavigationServiceMock();
        httpMock.get.mockReturnValue({
            pipe: (args: any) => {
                return [];
            }
        });
        httpMock.put.mockReturnValue(of({}));
        service = new CurrenciesService(httpMock as any, gridNavigationService as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });
    it('should get viewData', () => {
        service.getViewData();
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/currencies/viewdata');
    });
    it('should call the getCurrencies api correctly ', () => {
        const criteria = {};
        jest.spyOn(gridNavigationService, 'init');
        service.getCurrencies(criteria, null);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/currencies', { params: { params: 'null', q: JSON.stringify(criteria) } });
    });

    it('should call the getCurrencyDetails api correctly ', () => {
        service.getCurrencyDetails('AB');
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/currencies/AB');
    });

    it('should call the validate Currencycode api correctly ', () => {
        service.validateCurrencyCode('AB');
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/currencies/validate/AB');
    });
    it('should call the getExchangeRateHistory api correctly ', () => {
        service.getHistory('ABC', null);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/currencies/history/ABC', { params: { params: 'null' } });
    });
    it('should call the getCurrencyDesc api correctly ', () => {
        service.getCurrencyDesc('ABC');
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/currencies/currency-desc/ABC');
    });

    describe('Deleting Currency', () => {
        it('calls the correct API passing the parameters', () => {
            const inUseIds = { ids: ['AUS'] };
            service.deleteCurrencies(['AUS']);
            expect(httpMock.request).toHaveBeenCalled();
            expect(httpMock.request.mock.calls[0][0]).toBe('delete');
            expect(httpMock.request.mock.calls[0][1]).toBe('api/configuration/currencies/delete');
            expect(httpMock.request.mock.calls[0][2]).toEqual({ body: inUseIds });

        });
    });

    describe('Saving Currency', () => {
        it('calls the correct API passing the parameters', () => {
            const entry: CurrencyRequest = {
                id: 'AB',
                currencyCode: 'AB',
                currencyDescription: 'Code desc',
                dateChanged: new Date(),
                buyFactor: 1,
                sellFactor: 1.5,
                roundedBillValues: 2.5,
                buyRate: 5,
                bankRate: 5,
                sellRate: 7.5
            };
            service.submitCurrency(entry);
            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/currencies/AB', entry);
        });
        it('calls the correct API passing the parameters', () => {
            const entry: CurrencyRequest = {
                currencyCode: 'AB',
                currencyDescription: 'Code desc',
                dateChanged: new Date(),
                buyFactor: 1,
                sellFactor: 1.5,
                roundedBillValues: 2.5,
                buyRate: 5,
                bankRate: 5,
                sellRate: 7.5
            };
            service.submitCurrency(entry);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/currencies', entry);
        });
    });
});