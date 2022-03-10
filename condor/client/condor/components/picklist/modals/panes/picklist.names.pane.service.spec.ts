module inprotech.components.picklist {
    'use strict';
    describe('inprotech.components.picklist.PicklistNamesPaneService', () => {
        'use strict';

        let service: IPicklistNamesPaneService, httpMock: any, promiseMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.components.picklist');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
                promiseMock = $injector.get<any>('promiseMock');
            });
        });

        beforeEach(inject((PicklistNamesPaneService: IPicklistNamesPaneService) => {
            service = PicklistNamesPaneService;
        }));

        describe('getName', () => {
            it('should include name id in uri', () => {
                service.getName(123);
                expect(httpMock.get).toHaveBeenCalledWith('api/picklists/names/123');
            });
        });
    });
}