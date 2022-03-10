describe('inprotech.configuration.general.validcombination.ValidPicklistMaintenanceController', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(validPicklistService) {
        service = validPicklistService;
    }));

    describe('get picklist values from server', function() {
        it('should get property types', function() {
            var entry = {
                propertyTypeModel: {
                    code: 'P'
                }
            }
            service.getPropertyType(entry);

            expect(httpMock.get).toHaveBeenCalledWith('api/picklists/propertyTypes/retrieve/' + entry.propertyTypeModel.code);
        });
    });
    describe('get case category picklist values from server', function() {
        it('should get case categories', function() {
            var entry = {
                caseTypeModel: {
                    key: 'P'
                },
                caseCategoryModel: {
                    key: 1,
                    code: 'B'
                }
            }
            service.getCaseCategory(entry);

            expect(httpMock.get).toHaveBeenCalledWith('api/picklists/caseCategories/' + entry.caseCategoryModel.code + '/' + entry.caseTypeModel.code);
        });
    });
});