describe('inprotech.components.picklist', function () {
    'use strict';

    var service, httpMock, response

    beforeEach(function () {
        module('inprotech.components.picklist');
        module(function ($provide) {
            var $injector = angular.injector(['inprotech.mocks']);
            httpMock = $injector.get('httpMock');

            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function (picklistMaintenanceService) {
        service = picklistMaintenanceService;
    }));

    describe('init', function () {
        it('should init with correct data for restmode objects', function () {

            var obj = service.resolve('caseTest');
            response = {};
            obj.init(function (data) { response = data; }, false, null);

            expect(httpMock.get).toHaveBeenCalledWith('api/picklists/caseTest/meta');
            expect(obj.session).toEqual({ apiUrl: 'api/picklists/caseTest' });
            expect(obj.$search).toBeDefined();
            expect(obj.$build).toBeDefined();

        });
        it('should init with correct data for simple objects', function () {

            var obj = service.resolve('caseTest');
            response = {};
            obj.init(function (data) { response = data; }, true, 'api/picklist/casetest');

            expect(httpMock.get).not.toHaveBeenCalled();
            expect(obj.session).toEqual({ apiUrl: 'api/picklist/casetest' });
            expect(obj.$search).toBeDefined();
            expect(obj.$build).toBeDefined();
            expect(response).toBeDefined();
            expect(response.columns).toBeDefined();
        });

        it('should return $seach with correct datamodel', function () {

            var obj = service.resolve('caseTest');
            response = {};
            obj.init(function (data) { response = data; }, true, 'api/picklists/casetest');

            var returnValue = {
                data: {
                    data: 'testValue'
                }
            }
            httpMock.get.returnValue = (angular.copy(returnValue));

            var response = obj.$search('11011').$asPromise();
            var encodeResponse = response.$encode();
            expect(httpMock.get).toHaveBeenCalledWith('api/picklists/casetest', { params: '11011' });
            expect(response.data).toEqual('testValue');
            expect(response.$metadata).toEqual(returnValue);
            expect(encodeResponse.data).toEqual('testValue');
        });

        it('should return $build with correct datamodel', function () {

            var obj = service.resolve('caseTest');
            response = {};
            obj.init(function (data) { response = data; }, true, 'api/picklists/casetest');

            var returnValue = {
                data: 'testValue'
            }

            obj.$build(returnValue).$then(function (data) { response = data; });

            expect(httpMock.get).not.toHaveBeenCalled();
            expect(response.data).toEqual('testValue');
        });

        it('should return $find with correct datamodel with additional identifiers', function () {

            var obj = service.resolve('caseTest');
            response = {};
            obj.init(function (data) { response = data; }, true, 'api/picklists/casetest');

            var returnValue = {
                data: {
                    data: 'testValue'
                }
            }
            httpMock.get.returnValue = (angular.copy(returnValue));

            obj.$find('10011', { key2: '10011r' }).$then(function (data) { response = data; });

            expect(httpMock.get).toHaveBeenCalledWith('api/picklists/casetest/10011', { params: { key2: '10011r' } });
            expect(response.data).toEqual('testValue');
        });

    });

    describe('Common functions', function () {
        it('should extend return model with common functions', function () {

            var obj = service.resolve('caseTest');
            response = {};
            obj.init(function (data) { response = data; }, false, null);
            var returnValue = {
                data: {
                    data: 'testValue'
                }
            }
            httpMock.get.returnValue = (angular.copy(returnValue));

            obj.$find('10011', { key2: '10011r' }).$then(function (data) { response = data; });
            expect(response.$on).toBeDefined();
            expect(response.$off).toBeDefined();
            expect(response.$duplicate).toBeDefined();
            expect(response.$destroy).toBeDefined();
            expect(response.$save).toBeDefined();
            expect(response.withParams).toBeDefined();

            obj.$build(returnValue).$then(function (data) { response = data; });
            expect(response.$on).toBeDefined();
            expect(response.$off).toBeDefined();
            expect(response.$duplicate).toBeDefined();
            expect(response.$destroy).toBeDefined();
            expect(response.$save).toBeDefined();
            expect(response.withParams).toBeDefined();

            response = obj.$search('11011').$asPromise();
            expect(response.$on).toBeDefined();
            expect(response.$off).toBeDefined();
            expect(response.$duplicate).toBeDefined();
            expect(response.$destroy).toBeDefined();
            expect(response.$save).toBeDefined();
            expect(response.withParams).toBeDefined();
        });


        it('should return $duplicate with correct datamodel', function () {
            var obj = service.resolve('caseTest');
            var response = {};
            obj.init(function (data) { response = data; }, true, 'api/picklists/casetest');

            var returnValue = {
                data: {
                    data: 'testValue'
                }
            }
            httpMock.get.returnValue = (angular.copy(returnValue));

            obj.$find('10011', { key2: '10011r' }).$then(function (data) { response = data; });

            var responseCopy = response.$duplicate();

            expect(responseCopy.data).toEqual('testValue');
            expect(responseCopy.session).toBeUndefined();
        });

        it('should return $destroy with correct datamodel', function () {
            var obj = service.resolve('caseTest');
            var response = {};
            obj.init(function (data) { response = data; }, true, 'api/picklists/casetest');

            var returnValue = {
                data: {
                    key: '10011', value: 'testValue'
                }
            }
            httpMock.get.returnValue = (angular.copy(returnValue));

            obj.$find('10011').$then(function (data) { response = data; });

            response.withParams({ key2: '10011r' }).$destroy();
            expect(httpMock.delete).toHaveBeenCalledWith('api/picklists/casetest/10011', { params: { key2: '10011r' } });

        });
        it('should return $save as new when no Key is presented', function () {
            var obj = service.resolve('caseTest');
            var response = {};
            obj.init(function (data) { response = data; }, true, 'api/picklists/casetest');

            var returnValue = {
                key: '10011', value: 'testValue'
            }

            obj.$build(returnValue).$then(function (data) { response = data; });

            response.$save();
            expect(httpMock.put).toHaveBeenCalledWith('api/picklists/casetest/10011', { key: '10011', value: 'testValue' });

            var newValue = {
                key: null, value: 'testNewValue'
            }
            obj.$build(newValue).$then(function (data) { response = data; });

            response.$save();
            expect(httpMock.post).toHaveBeenCalledWith('api/picklists/casetest', { value: 'testNewValue' });
        });

        it('should regist the event with $on', function () {
            var obj = service.resolve('caseTest');
            var response = {};
            obj.init(function (data) { response = data; }, true, 'api/picklists/casetest');

            var returnValue = {
                key: '10011', value: 'testValue'
            }
            obj.$build(returnValue).$then(function (data) { response = data; });

            var testFunction = jasmine.createSpy();

            response.$on('after-save', testFunction).$save();
            expect(httpMock.put).toHaveBeenCalledWith('api/picklists/casetest/10011', { key: '10011', value: 'testValue' });
            expect(testFunction).toHaveBeenCalled();
        });
    });
});