import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { ExchangeRateVariationRequest } from './exchange-rate-variations.model';
import { ExchangeRateVariationService } from './exchange-rate-variations.service';
describe('ExchangeRateVariationService', () => {
    let service: ExchangeRateVariationService;
    let httpMock: HttpClientMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        httpMock.get.mockReturnValue({
            pipe: (args: any) => {
                return [];
            }
        });
        httpMock.put.mockReturnValue(of({}));
        service = new ExchangeRateVariationService(httpMock as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });
    it('should get viewData', () => {
        service.getViewData(null);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/exchange-rate-variation/permissions/CUR');

        service.getViewData('1');
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/exchange-rate-variation/permissions/EXS');
    });
    it('should call the getExchangeRateVariations api correctly ', () => {
        const criteria = {};
        service.getExchangeRateVariations(criteria, null);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/exchange-rate-variation', { params: { params: 'null', q: JSON.stringify(criteria) } });
    });

    it('calls the correct delete API passing the parameters', () => {
        const exchangeRateVariationIds = { ids: [1] };
        service.deleteExchangeRateVariations([1]);
        expect(httpMock.request).toHaveBeenCalled();
        expect(httpMock.request.mock.calls[0][0]).toBe('delete');
        expect(httpMock.request.mock.calls[0][1]).toBe('api/configuration/exchange-rate-variation/delete');
        expect(httpMock.request.mock.calls[0][2]).toEqual({ body: exchangeRateVariationIds });

    });

    it('should call the getExchangeRateVariationDetails api correctly ', () => {
        service.getExchangeRateDetails(1);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/exchange-rate-variation/1');
    });

    it('should call the validate ExchangerateVariation api correctly ', () => {
        const request: ExchangeRateVariationRequest = {
            id: 1,
            currencyCode: 'AB',
            exchRateSchId: null,
            buyRate: null,
            buyFactor: 1,
            sellRate: null,
            sellFactor: 1,
            caseCategoryCode: 'P',
            caseTypeCode: null,
            subTypeCode: null,
            countryCode: 'AU',
            effectiveDate: new Date(),
            notes: 'Notes'
        };
        service.validateExchangeRateVariations(request);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/exchange-rate-variation/validate', request);
    });

    describe('Saving ExchangeRate Variation Details', () => {
        it('calls the correct API passing the parameters', () => {
            const request: ExchangeRateVariationRequest = {
                id: 1,
                currencyCode: 'AB',
                exchRateSchId: null,
                buyRate: null,
                buyFactor: 1,
                sellRate: null,
                sellFactor: 1,
                caseCategoryCode: 'P',
                caseTypeCode: null,
                subTypeCode: null,
                countryCode: 'AU',
                effectiveDate: new Date(),
                notes: 'Notes'
            };
            service.submitExchangeRateVariations(request);
            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/exchange-rate-variation/1', request);
        });
        it('calls the correct API passing the parameters', () => {
            const entry: ExchangeRateVariationRequest = {
                currencyCode: 'AB',
                exchRateSchId: null,
                buyRate: null,
                buyFactor: 1,
                sellRate: null,
                sellFactor: 1,
                caseCategoryCode: 'P',
                caseTypeCode: null,
                subTypeCode: null,
                countryCode: 'AU',
                effectiveDate: new Date(),
                notes: 'Notes'
            };
            service.submitExchangeRateVariations(entry);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/exchange-rate-variation', entry);
        });
    });
});