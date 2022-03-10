import { of } from 'rxjs';
import { ExchangeRateVariationPermissions } from './exchange-rate-variations.model';

export class ExchangeRateVariationServiceMock {
    private readonly permissions = new ExchangeRateVariationPermissions();
    getExchangeRateVariations = jest.fn().mockReturnValue(of([{ id: 1, currency: 'AUD' }]));
    getViewData = jest.fn().mockReturnValue(of(this.permissions));
    deleteExchangeRateVariations = jest.fn().mockReturnValue(of({ result: 'success' }));
}