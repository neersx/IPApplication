describe('inprotech.configuration.general.jurisdictions.jurisdictionAttributesService', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');

            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(jurisdictionAttributesService) {
        service = jurisdictionAttributesService;
    }));

    describe('listing', function() {
        it('should pass correct parameters', function() {
            var id = 'AT';
            var queryParams = {
                sortBy: 'id',
                sortDir: 'asc',
                skip: 1,
                take: 2
            };
            service.listAttributes(queryParams, id);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/jurisdictions/maintenance/attributes/' + id, {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });
    describe('getAttributeTypes', function() {
        it('should call JurisdictionAttributeTypes picklist', function() {
            service.getAttributeTypes();
            expect(httpMock.get).toHaveBeenCalledWith('api/picklists/JurisdictionAttributeTypes');
        });
    });
    describe('getAttributes', function() {
        it('should pass correct parameters', function() {
            var typeId = 2;
            service.getAttributes(typeId);
            expect(httpMock.get).toHaveBeenCalledWith('api/picklists/tablecodes?tableType=' + typeId);
        });
    });
});