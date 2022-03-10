import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { NameDetailsService } from './name-details.service';
describe('NameDetailsService', () => {
    let httpClientSpy: HttpClientMock;
    let service: NameDetailsService;
    beforeEach(() => {
        httpClientSpy = new HttpClientMock();
        service = new NameDetailsService(httpClientSpy as any);
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('getCaseRenewalsData', () => {
        it('should pass correct encoded parameters', () => {
            service.getFirstEmailTemplate(12345, 'A', 1);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12345/names/email-template', {params: {params: '{"caseKey":12345,"nameType":"A","sequence":1}', resolve: 'false'}});
        });
    });
});