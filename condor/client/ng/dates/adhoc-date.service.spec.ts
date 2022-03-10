import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs/internal/observable/of';
import { AdHocDate, BulkFinaliseRequestModel, FinaliseRequestModel } from './adhoc-date.model';
import { AdhocDateService } from './adhoc-date.service';

describe('FinaliseAdHocDateComponent', () => {
    let service: AdhocDateService;
    const httpMock = new HttpClientMock();
    beforeEach(() => {
        service = new AdhocDateService(httpMock as any);
    });
    it('should create', async(() => {
        expect(service).toBeTruthy();
    }));

    it('should call adhocDate', () => {
        const id = 10;
        const response = new AdHocDate();
        response.adHocDateFor = 'ADHOC';
        response.message = 'Message';
        response.finaliseReference = '1';
        httpMock.get.mockReturnValue(of(response));
        service.adhocDate = jest.fn().mockReturnValue(of(response));
        service.adhocDate(id).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result.adHocDateFor).toBe('ADHOC');
                expect(result.message).toBe('Message');
            }
        );
    });

    it('should call finaliseAdhocDate', () => {
        const response = true;
        const request = new FinaliseRequestModel();
        request.alertId = 10;
        request.userCode = '2';
        httpMock.put.mockReturnValue(of(response));
        service.finalise = jest.fn().mockReturnValue(of(response));
        service.finalise(request).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result).toBe(true);
            }
        );
    });

    it('should call bulkFinaliseAdhocDate', () => {
        const response = true;
        const request = new BulkFinaliseRequestModel();
        request.selectedTaskPlannerRowKeys = ['10', '11'];
        request.userCode = '2';
        httpMock.put.mockReturnValue(of(response));
        service.bulkFinalise = jest.fn().mockReturnValue(of(response));
        service.bulkFinalise(request).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result).toBe(true);
            }
        );
    });

    it('should call saveAdhocDate', () => {
        const response = true;
        const request = { employeeNo: 1, caseId: 2 };
        httpMock.put.mockReturnValue(of(response));
        service.saveAdhocDate = jest.fn().mockReturnValue(of(response));
        service.saveAdhocDate(request).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result).toBe(true);
            }
        );
    });

    it('should call saveAdhocDate', () => {
        const response = true;
        const request = { employeeNo: 1, caseId: 2 };
        httpMock.put.mockReturnValue(of(response));
        service.saveAdhocDate = jest.fn().mockReturnValue(of(response));
        service.saveAdhocDate(request).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result).toBe(true);
            }
        );
    });

    it('should call viewData', () => {
        const response = { adHocDateFor: 'ADHOC', message: 'Message', reference: '1' };
        httpMock.get.mockReturnValue(of(response));
        service.viewData = jest.fn().mockReturnValue(of(response));
        service.viewData().subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result.adHocDateFor).toBe('ADHOC');
                expect(result.message).toBe('Message');
            }
        );
    });

    it('should call caseEventDetails', () => {
        const response = { Key: 1, value: '2' };
        const request = 45;
        httpMock.get.mockReturnValue(of(response));
        service.caseEventDetails = jest.fn().mockReturnValue(of(response));
        service.caseEventDetails(request).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result).toBe(response);
            }
        );
    });
    it('should call nameDetails', () => {
        const response = { Key: 1, value: '2' };
        const request = 45;
        httpMock.get.mockReturnValue(of(response));
        service.nameDetails = jest.fn().mockReturnValue(of(response));
        service.nameDetails(request).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result).toBe(response);
            }
        );
    });

    it('should call nameTypeRelationShip', () => {
        const response = { Key: 1, value: '2' };
        httpMock.get.mockReturnValue(of(response));
        service.nameTypeRelationShip = jest.fn().mockReturnValue(of(response));
        service.nameTypeRelationShip(4, 'A', 'EMP').subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result).toBe(response);
            }
        );
    });

    it('should call delete', () => {
        const response = true;
        const request = 45;
        httpMock.delete.mockReturnValue(of(response));
        service.delete = jest.fn().mockReturnValue(of(response));
        service.caseEventDetails(request).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result).toBe(response);
            }
        );
    });
});