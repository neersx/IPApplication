import { HttpClientMock } from 'mocks';
import { AccountingService } from './accounting.service';

describe('AccountingService', () => {
    let httpClientSpy: any;
    let service: AccountingService;

    beforeEach(() => {
        httpClientSpy = new HttpClientMock();
        service = new AccountingService(httpClientSpy);
    });

    it('should exist', () => {
        expect(service).toBeDefined();
    });

    describe('getReceivableBalance', () => {
        it('should call the correct url with params', () => {
            service.getReceivableBalance(54321);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/name/54321/receivables', {headers: undefined});
        });
        it('should call the correct url with cache header', () => {
            service.getReceivableBalance(54321, true);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/accounting/name/54321/receivables', { headers: expect.any(Object) });
        });
    });

});