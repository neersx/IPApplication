'use strict';
namespace Inprotech.Integration.PtoAccess.sponsorshipService {
    declare let test: any;
    describe('sponsorship service', () => {
        let service, httpMock;
        beforeEach(() => {
            angular.mock.module('Inprotech.Integration.PtoAccess');
            angular.mock.module(() => {
                httpMock = test.mock('$http', 'httpMock');
            });
            inject((sponsorshipService) => {
                service = sponsorshipService;
            });
        });

        it('get sponsorship', () => {
            service.get();
            expect(httpMock.get).toHaveBeenCalledWith('api/ptoaccess/uspto/privatepair/sponsorships');
        });

        it('delete', () => {
            service.delete(123);
            expect(httpMock.delete).toHaveBeenCalledWith('api/ptoaccess/uspto/privatepair/sponsorships/123');
        });

        it('create', () => {
            service.addOrUpdate({}, false);
            expect(httpMock.post).toHaveBeenCalledWith('api/ptoaccess/uspto/privatepair/sponsorships', {});
        });

        it('update', () => {
            service.addOrUpdate({}, true);
            expect(httpMock.patch).toHaveBeenCalledWith('api/ptoaccess/uspto/privatepair/sponsorships', {});
        });
    });
}