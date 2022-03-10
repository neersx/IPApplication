import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { DebtorRestrictionsService } from './debtor-restriction.service';
describe('DebtorRestrictionFlagComponent', () => {
    let httpClientSpy: HttpClientMock;
    let service: DebtorRestrictionsService;
    beforeEach(() => {
        httpClientSpy = new HttpClientMock();
        service = new DebtorRestrictionsService(httpClientSpy as any);
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('getRestrictions', () => {
        it('should call the API at most once for each key', async(() => {
            httpClientSpy.get.mockReturnValue(of([1]));
            service.getRestrictions(1).subscribe((restrictionValue1) => {
                expect(httpClientSpy.get).toHaveBeenCalledWith('api/names/restrictions', expect.anything());
                expect(httpClientSpy.get).toHaveBeenCalledTimes(1);
                expect(restrictionValue1).toEqual([1]);

                service.getRestrictions(1).subscribe(restrictionValue2 => {
                    expect(httpClientSpy.get).toHaveBeenCalledTimes(1);
                    expect(restrictionValue2).toEqual([1]);

                    httpClientSpy.get.mockReturnValue(of([2]));
                    service.getRestrictions(2).subscribe(restrictionValue3 => {
                        expect(httpClientSpy.get).toHaveBeenCalledTimes(2);
                        expect(restrictionValue3).toEqual([2]);
                    });
                });
            });
        }));
    });
});