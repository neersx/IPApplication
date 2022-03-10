import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { IpxDataItemService } from './ipx-dataitem-picklist.service';
describe('due date case search modal', () => {
    let service: IpxDataItemService;
    let httpMock: any;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        service = new IpxDataItemService(httpMock);
    });
    it('should create the service instance', async(() => {
        expect(service).toBeTruthy();
    }));

    it('should call validateSql', () => {
        const params = {
            isSqlStatement: false,
            sql: {
                storedProcedure: 'ipw_ListBackgroundProcesses'
            }
        };
        httpMock.post.mockReturnValue(of([]));
        service.validateSql(params);
        spyOn(httpMock, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    });

});