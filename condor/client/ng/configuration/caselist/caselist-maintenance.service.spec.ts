import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { CaselistMaintenanceService } from './caselist-maintenance.service';

describe('CaselistMaintenanceService', () => {
    let service: CaselistMaintenanceService;
    const httpMock = new HttpClientMock();
    beforeEach(() => {
        service = new CaselistMaintenanceService(httpMock as any);
    });
    it('should create the service', async(() => {
        expect(service).toBeTruthy();
    }));

    it('validate deleteList with casekeys', () => {
        const caseKeys = [10, 20, 55];
        service.deleteList(caseKeys);
        expect(httpMock.post).toHaveBeenCalledWith('api/picklists/CaseLists/deleteList', caseKeys);
    });

    it('validate getViewdata without casekeys', () => {
        const result = service.getViewdata();
        expect(httpMock.get).toHaveBeenCalledWith('api/picklists/CaseLists/viewdata');
    });

});
