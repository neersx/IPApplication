import { HttpParams } from '@angular/common/http';
import { HttpClientMock } from 'mocks';
import { NameViewService } from './name-view.service';

describe('inprotech.portfolio.cases.NameViewService', () => {
    'use strict';

    let service: NameViewService;
    let httpClientSpy;
    let data;

    beforeEach(() => {
        httpClientSpy = new HttpClientMock();
        service = new NameViewService(httpClientSpy);
        data = {
            supplierdetails: {}
        };
    });

    describe('getNameViewData', () => {
        it('should pass correct encoded parameters', () => {
            service.getNameViewData$(934);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/name/nameview/934/');
        });
        it('should pass programId where specified', () => {
            service.getNameViewData$(-909, 'NAMEPROGRAM');
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/name/nameview/-909/NAMEPROGRAM');
        });
    });

    describe('getSupplierDetails', () => {
        it('should pass correct encoded parameters', () => {
            service.getSupplierDetails$(69);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/name/69/supplier-details');
        });
    });

    describe('getNameInternalDetails', () => {
        it('should pass correct encoded parameters', () => {
            service.getNameInternalDetails$(6969);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/name/6969/internal-details');
        });
    });

    describe('getTrustAccountingDetails', () => {
        it('should pass correct encoded parameters', () => {
            service.getTrustAccountingDetails$(8, 6, 0, 888, null);
            const parameters = {
                params: new HttpParams()
                    .set('nameId', JSON.stringify(8))
                    .set('bankId', JSON.stringify(6))
                    .set('bankSeqId', JSON.stringify(0))
                    .set('entityId', JSON.stringify(888))
                    .set('params', JSON.stringify(null))
            };
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/name/trust-accounting-details/', parameters);
        });
    });

    describe('maintainNameData', () => {
        it('should pass correct parameters', () => {
            service.maintainName$(data);
            expect(httpClientSpy.post).toHaveBeenCalledWith('api/name/nameview/maintenance/', data);
        });
    });

    describe('maintainNameData', () => {
        it('Validate to get trust accounting check results', () => {
            const request = {
                    skip: 0,
                    take: 10,
                    filters: null
                };
            service.getTrustAccounting$(12, request);
            expect(httpClientSpy.post).toHaveBeenCalledWith('api/name/12/trust-accounting', request);
        });
    });
});