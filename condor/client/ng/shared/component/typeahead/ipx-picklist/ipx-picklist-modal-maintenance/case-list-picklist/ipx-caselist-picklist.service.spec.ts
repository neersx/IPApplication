import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { IpxCaselistPicklistService } from './ipx-caselist-picklist.service';

describe('IpxCaselistPicklistService', () => {
    let service: IpxCaselistPicklistService;
    const httpMock = new HttpClientMock();
    beforeEach(() => {
        service = new IpxCaselistPicklistService(httpMock as any);
    });
    it('should create the service', async(() => {
        expect(service).toBeTruthy();
    }));

    it('validate getCasesListItems with casekeys', () => {
        const caseKeys = [10, 20, 55];
        const primeCaseKey = 100;
        const queryParams = {
            skip: 10,
            take: 20
        };
        const newlyAddedCaseKeys = [100];
        service.getCasesListItems$(caseKeys, primeCaseKey, queryParams, newlyAddedCaseKeys);
        expect(httpMock.post).toHaveBeenCalledWith('api/picklists/CaseLists/cases/', { caseKeys, queryParameters: queryParams, primeCaseKey, newlyAddedCaseKeys });
    });

    it('validate getCasesListItems without casekeys', () => {
        const caseKeys = [];
        const primeCaseKey = 100;
        const queryParams = {
            skip: 10,
            take: 20
        };
        const newlyAddedCaseKeys = [100];
        const result = service.getCasesListItems$(caseKeys, primeCaseKey, queryParams, newlyAddedCaseKeys);
        expect(result._isScalar).toEqual(of([])._isScalar);
        expect(result.operator).toEqual(of([]).operator);
        expect(result.source).toEqual(of([]).source);
    });

    it('validate updateCasesListItems', () => {
        const caseListId = 11;
        const caseList = { caseKeys: [12, 13, 14], value: 'list name', newlyAddedCaseKeys: [12] };
        service.updateCasesListItems$(caseListId, caseList);
        expect(httpMock.put).toHaveBeenCalledWith('api/picklists/CaseLists/' + caseListId, caseList);
    });

});
