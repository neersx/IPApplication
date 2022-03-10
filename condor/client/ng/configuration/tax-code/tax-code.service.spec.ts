import { async } from '@angular/core/testing';
import { LocalSettings } from 'core/local-settings';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { GridNavigationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { TaxCodes } from './tax-code.model';
import { TaxCodeService } from './tax-code.service';

describe('RoleSearchService', () => {
    let service: TaxCodeService;
    let httpClientSpy = { get: jest.fn(), post: jest.fn() };
    let localSettings: LocalSettings;
    const gridNavigationService = new GridNavigationServiceMock();
    beforeEach(() => {
        localSettings = new LocalSettingsMock();
        httpClientSpy = {
            get: jest.fn().mockReturnValue({
                pipe: (args: any) => {
                    return [];
                }
            }), post: jest.fn()
        };
        service = new TaxCodeService(httpClientSpy as any, gridNavigationService as any, localSettings);
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });
    it('should call the markInUseRoles method', () => {
        const data = [{ id: 1, persisted: true, inUse: false, selected: false },
        { id: 2, persisted: true, inUse: false, selected: false }];
        service.inUseTaxCode = [1];
        service.markInUse(data);
        expect(data[0].persisted).toEqual(false);
        expect(data[0].inUse).toEqual(true);
        expect(data[0].selected).toEqual(true);
    });
    it('should call the overviewDetails method', async(() => {
        httpClientSpy.get.mockReturnValue(of([]));
        service.overviewDetails(1);
        expect(httpClientSpy.get).toHaveBeenCalled();
        spyOn(httpClientSpy, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));
    it('should call the taxRatesDetails method', async(() => {
        httpClientSpy.get.mockReturnValue(of([]));
        service.taxRatesDetails(1);
        expect(httpClientSpy.get).toHaveBeenCalled();
        spyOn(httpClientSpy, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));
    it('should call getTaxCodes', () => {
        httpClientSpy.get.mockReturnValue(of([]));
        spyOn(service, 'getTaxCodes').and.returnValue(of([]));
        service.getTaxCodes(null, null);
        spyOn(httpClientSpy, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    });
    it('should call the saveTaxCode method', async(() => {
        httpClientSpy.post.mockReturnValue(of({ reslt: true }));
        const request = new TaxCodes();
        request.taxCode = 'TaxCode1';
        request.description = 'Tax Code Description';
        service.saveTaxCode(request);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));
    it('should call the deleteTaxCodes method', async(() => {
        httpClientSpy.post.mockReturnValue(of({ reslt: true }));
        service.deleteTaxCodes([1, 2, 3]);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));

    it('should call the updateTaxCodeDetails method', async(() => {
        httpClientSpy.post.mockReturnValue(of({ reslt: true }));
        const request: any = {};
        request.id = 1;
        request.taxCode = 'TaxCode1';
        request.description = 'Tax Code Description';
        service.updateTaxCodeDetails(request);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));
});