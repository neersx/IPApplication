module inprotech.portfolio.cases {
    'use strict';
    describe('inprotech.portfolio.cases.CaseViewService', () => {
        'use strict';

        let service: ICaseViewService, httpMock: any, sharedService: ICaseSharedService;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((CaseViewService: ICaseViewService, CaseSharedService: ICaseSharedService) => {
            service = CaseViewService;
            sharedService = CaseSharedService;
        }));

        describe('getOverview', () => {
            it('should pass correct encoded parameters', () => {
                spyOn(sharedService, 'getCaseKeyFromRowKey').and.returnValue(12345);
                service.getOverview( '368', 12345);
                expect(httpMock.get).toHaveBeenCalledWith('api/case/12345/overview');
            });
            it('should use Id if rowKey is not provided', () => {
                spyOn(sharedService, 'getCaseKeyFromRowKey').and.returnValue(null);
                service.getOverview( '368', null);
                expect(httpMock.get).toHaveBeenCalledWith('api/case/368/overview');
            });
        });
        describe('getPropertyTypeIcon', () => {
            it('should pass correct encoded parameters', () => {
                service.getPropertyTypeIcon('12345');
                expect(httpMock.get).toHaveBeenCalledWith('api/shared/image/12345/20/20', Object({ cache: true }));
            });
        });
        describe('getScreenControl', () => {
            it('should pass correct encoded parameters without programId', () => {
                service.getScreenControl('12345');
                expect(httpMock.get).toHaveBeenCalledWith('api/case/screencontrol/12345/');
            });
            it('should pass correct encoded parameters', () => {
                service.getScreenControl('12345', 'CASETEXT');
                expect(httpMock.get).toHaveBeenCalledWith('api/case/screencontrol/12345/CASETEXT');
            });
        });
        describe('getIppAvailability', () => {
            it('should pass correct encoded parameters', () => {
                service.getIppAvailability('12345');
                expect(httpMock.get).toHaveBeenCalledWith('api/case/12345/ipp-availability');
            });
        });
        describe('getImportanceLevelAndEventNoteTypes', () => {
            it('should pass correct encoded parameters', () => {
                let result = {
                    importanceLevel: 5,
                    importanceLevelOptions: [{ code: 1, description: 'imp1' },
                    { code: 2, description: 'imp2' }],
                    requireImportanceLevel: true,
                    eventNoteTypes: []
                }
                httpMock.get.returnValue = result;
                let r: any = service.getImportanceLevelAndEventNoteTypes();
                expect(httpMock.get).toHaveBeenCalledWith('api/case/importance-levels-note-types', Object({ cache: true }));
                expect(r).toEqual(result);
            });
        });
    });
}
