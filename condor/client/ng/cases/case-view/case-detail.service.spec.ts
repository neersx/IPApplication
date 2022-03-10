import { HttpParams } from '@angular/common/http';
import { CaseNavigationServiceMock } from 'cases/core/case-navigation.service.mock';
import { HttpClientMock } from 'mocks';
import { CaseDetailService } from './case-detail.service';

describe('inprotech.portfolio.cases.CaseDetailService', () => {
    'use strict';

    let service: CaseDetailService;
    let httpClientSpy;
    let caseNavSpy: CaseNavigationServiceMock;

    beforeEach(() => {
        httpClientSpy = new HttpClientMock();
        caseNavSpy = new CaseNavigationServiceMock();
        service = new CaseDetailService(httpClientSpy, caseNavSpy as any);
    });

    describe('getOverview', () => {
        it('should pass correct id parameters', () => {
            caseNavSpy.getCaseKeyFromRowKey.mockReturnValue(12345);
            service.getOverview$('368', 12345);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/368/overview');
        });
        it('should use rowkey if id is not provided', () => {
            caseNavSpy.getCaseKeyFromRowKey.mockReturnValue(487);
            service.getOverview$(null, 487);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/487/overview');
        });
    });

    describe('getIppAvailability', () => {
        it('should pass correct encoded parameters', () => {
            service.getIppAvailability$(12345);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12345/ipp-availability');
        });
    });

    describe('getCaseWebLinks', () => {
        it('should pass correct encoded parameters', () => {
            service.getCaseWebLinks$(12345);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12345/weblinks');
        });
    });

    describe('getCaseSupportUri', () => {
        it('should pass correct encoded parameters', () => {
            service.getCaseSupportUri$(12345);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12345/support-email');
        });
    });

    describe('getScreenControl', () => {
        it('should pass correct encoded parameters without programId', () => {
            service.getScreenControl$(12345, undefined);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/screencontrol/12345/');
        });
        it('should pass correct encoded parameters', () => {
            service.getScreenControl$(12345, 'CASETEXT');
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/screencontrol/12345/CASETEXT');
        });
    });

    describe('getCaseViewData', () => {
        it('should pass correct encoded parameters', () => {
            service.getCaseViewData$();
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/caseview');
        });
    });

    describe('getCaseRenewalsData', () => {
        it('should pass correct encoded parameters', () => {
            service.getCaseRenewalsData$(12345, 111);
            const parameters = {
                params: new HttpParams()
                    .set('screenCriteriaKey', JSON.stringify(111))
            };
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12345/renewals', parameters);
        });
    });

    describe('getCaseProgram', () => {
        it('should pass correct encoded parameters', () => {
            service.getCaseProgram$('casentry');
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/program?programId=casentry');
        });
    });

    describe('getStandingInstructions', () => {
        it('should pass correct encoded parameters', () => {
            service.getStandingInstructions$(12345);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12345/standing-instructions');
        });
    });

    describe('getCaseInternalDetails', () => {
        it('should pass correct encoded parameters', () => {
            service.getCaseInternalDetails$(12345);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12345/internal-details');
        });
    });

    describe('getCustomContentData', () => {
        it('should pass correct encoded parameters', () => {
            service.getCustomContentData$(487, 1084);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/custom-content/case/487/item/1084');
        });
    });

    describe('getChecklistTypes', () => {
        it('should pass correct parameters', () => {
            service.getCaseChecklistTypes$(12345);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12345/checklist-types');
        });
    });

    describe('getCaseChecklistData', () => {
        it('should pass correct parameters', () => {
            service.getCaseChecklistData$(8, 6, null);
            const parameters = {
                params: new HttpParams()
                    .set('checklistCriteriaKey', JSON.stringify(6))
                    .set('params', JSON.stringify(null))
            };
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/8/checklists', parameters);
        });
    });

    describe('getCaseChecklistDataHybrid', () => {
        it('should pass correct parameters', () => {
            service.getCaseChecklistDataHybrid$(12, 11);
            const parameters = {
                params: new HttpParams()
                    .set('checklistCriteriaKey', JSON.stringify(11))
            };
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12/checklists-hybrid', parameters);
        });
    });

    describe('getChecklistDocuments', () => {
        it('should pass correct parameters', () => {
            service.getChecklistDocuments$(12, 11);
            const parameters = {
                params: new HttpParams()
                    .set('checklistCriteriaKey', JSON.stringify(11))
            };
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/12/checklistsDocuments', parameters);
        });
    });
    describe('getCaseIdFromIrn', () => {
        it('should pass correct parameters', () => {
            const caseRef = '1234/a';
            service.getCaseId$(caseRef);
            const parameters = {
                params: new HttpParams()
                    .set('caseRef', encodeURI(caseRef))
            };
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/case/caseId', parameters);
            expect(service.getCaseIdCalls.has(caseRef)).toBeTruthy();
        });

        it('should not call http get again', () => {
            const caseRef = '1234/a';
            service.getCaseId$(caseRef);
            expect(service.getCaseIdCalls.has(caseRef)).toBeTruthy();
            service.getCaseId$(caseRef);
            expect(httpClientSpy.get).toHaveBeenCalledTimes(1);
        });
    });
});
