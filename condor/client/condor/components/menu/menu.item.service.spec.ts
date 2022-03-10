module inprotech.components.menu {
    describe('inprotech.components.menu', () => {
        'use strict';

        let service: MenuItemService, httpMock: any;
        let response = {
            data: {
                hasDueDatePresentationColumn: true,
                hasAllDatePresentationColumn: undefined
            }
        }

        beforeEach(() => {
            angular.mock.module('inprotech.components.menu');
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
            httpMock = $injector.get('httpMock');
        });

        beforeEach(inject(function () {
            service = new MenuItemService(httpMock);
        }));

        describe('getDueDatePresentation', () => {
            it('should accept queryKey', () => {

                httpMock.get.returnValue = {
                    then: function (cb) {
                        return cb(response);
                    }
                };

                service.getDueDatePresentation('1');

                expect(httpMock.get).toHaveBeenCalledWith('api/search/case/dueDatePresentation/1', {
                    params: {
                        params: JSON.stringify('1')
                    }
                });
            });

        });

        describe('getDueDateSavedSearch', () => {
            it('should call the getDueDateSavedSearch with queryKey', () => {

                httpMock.get.returnValue = {
                    then: function (cb) {
                        return cb(response);
                    }
                };

                service.getDueDateSavedSearch('1');

                expect(httpMock.get).toHaveBeenCalledWith('api/search/case/casesearch/builder/1');
            });

        });
    });
}