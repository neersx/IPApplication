describe('Inprotech.SchemaMapping.xmlController', function() {
    'use strict';

    var _scope, _http, _window, _controller;

    beforeEach(module('Inprotech.SchemaMapping'));

    beforeEach(inject(function($rootScope, $controller, $httpBackend) {
        //_rootScope = $rootScope;
        _scope = $rootScope.$new();
        _http = $httpBackend;
        _window = {};

        _controller = function(stateParams) {
            stateParams = stateParams || { id: 1 };
            return $controller('xmlController', {
                '$scope': _scope,
                '$stateParams': stateParams,
                '$window': _window,
                'viewInitialiser': {
                    data: {
                        name: 'ohim'
                    }
                }
            });
        };
    }));

    afterEach(function() {
        _http.verifyNoOutstandingExpectation();
        _http.verifyNoOutstandingRequest();
        expect(_scope.status).toBe('idle');
    });

    describe('initialisation', function() {
        it('should set mapping name', function() {
            _controller();

            expect(_scope.mappingName).toBe('ohim');
        });
    });

    describe('generating xml', function() {
        beforeEach(function() {
            _controller({ id: 1 });

            _scope.details.entryPoint = 1;

            _scope.generateXml();
        });

        it('should display the valid xml returned from generation', function() {
            _http.expectGET('api/schemamappings/1/xmlview?gstrEntryPoint=1').respond(200, { result: '<?xml>' });

            _http.flush();

            expect(_scope.xml).toBe('<?xml>');
            expect(_scope.error).toBe(null);
        });

        it('should display error and invalid xml returned from generation', function() {
            var response = {
                xml: '<?xml>',
                error: 'error'
            };

            _http.expectGET('api/schemamappings/1/xmlview?gstrEntryPoint=1').respond(500, response);

            _http.flush();

            expect(_scope.xml).toBe('<?xml>');
            expect(_scope.error).toBe('error');
        });
    });

    describe('downloading xml', function() {
        beforeEach(function() {
            _controller({ id: 1 });

            _scope.details.entryPoint = 1;

            _scope.downloadXml();
        });

        it('should download the valid xml returned from generation', function() {
            _http.expectGET('api/schemamappings/1/xmldownload?gstrEntryPoint=1').respond(200, { result: '1' });

            _http.flush();

            expect(_window.location).toBe('api/storage/1');
            expect(_scope.error).toBe(null);
        });

        it('should display error and invalid xml returned from generation', function() {
            var response = {
                xml: '<?xml>',
                error: 'error'
            };

            _http.expectGET('api/schemamappings/1/xmldownload?gstrEntryPoint=1').respond(500, response);

            _http.flush();

            expect(_scope.xml).toBe('<?xml>');
            expect(_scope.error).toBe('error');
        });
    });
});