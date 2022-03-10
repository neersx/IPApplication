'use strict'
namespace inprotech.portfolio.cases {

    declare var test: any;

    describe('case view images service', function () {

        let service: () => ICaseViewImagesService, http;
        let s: ICaseViewImagesService;

        beforeEach(function () {
            angular.mock.module(function () {
                http = test.mock('$http', 'httpMock');
            });
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(inject(() => {
            service = () => {
                return new CaseViewImagesService(http);
            };
        }));

        it('returns case images from server', function () {
            s = service();
            expect(s).toBeDefined();

            s.getCaseImages(1);
            expect(http.get).toHaveBeenCalledWith('api/case/1/images');
        });
   });
}