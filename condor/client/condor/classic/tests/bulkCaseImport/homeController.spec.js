describe('Inprotech.BulkCaseImport.homeController', function() {
    'use strict';

    var _scope, _http, _rootScope, _controller, _fileReaderPromise, _csvParserPromise, notificationService;

    function buildFile(name, type, size) {
        return {
            name: name || 'a.xml',
            type: type || 'text/xml',
            size: size || 10
        };
    }

    beforeEach(function() {
        module('Inprotech.BulkCaseImport')
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.components.notification', 'inprotech.mocks.core']);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);
        });
    });

    beforeEach(inject(function($rootScope, $httpBackend, $controller, $q) {
        _http = $httpBackend;
        _rootScope = $rootScope;
        _scope = $rootScope.$new();

        _fileReaderPromise = $q.defer();

        var fileReader = {
            readAsText: jasmine.createSpy().and.returnValue(_fileReaderPromise.promise)
        };

        _csvParserPromise = $q.defer();

        var csvParser = {
            parse: jasmine.createSpy().and.returnValue(_csvParserPromise.promise)
        };

        _controller = function(viewData) {
            return $controller('homeController', {
                '$scope': _scope,
                'fileReader': fileReader,
                'csvParser': csvParser,
                'viewInitialiser': {
                    viewData: viewData || {
                        standardTemplates: [],
                        customTemplates: []
                    }
                }
            });
        };
    }));

    afterEach(function() {
        _http.verifyNoOutstandingExpectation();
        _http.verifyNoOutstandingRequest();
    });

    describe('check out the templates', function() {

        it('should build url each available templates', function() {

            var standard = ['a', 'b'];
            var custom = ['c', 'd'];

            _controller({
                standardTemplates: standard,
                customTemplates: custom
            });

            expect(_scope.standardTemplates[0]).toEqual({
                link: 'api/bulkcaseimport/template?type=standard&name=a',
                name: 'a'
            });

            expect(_scope.standardTemplates[1]).toEqual({
                link: 'api/bulkcaseimport/template?type=standard&name=b',
                name: 'b'
            });

            expect(_scope.customTemplates[0]).toEqual({
                link: 'api/bulkcaseimport/template?type=custom&name=c',
                name: 'c'
            });

            expect(_scope.customTemplates[1]).toEqual({
                link: 'api/bulkcaseimport/template?type=custom&name=d',
                name: 'd'
            });

        });

        it('should indicate there were no templates at all', function() {
            _controller({
                standardTemplates: [],
                customTemplates: []
            });

            expect(_scope.noTemplates).toBe(true);
        });

        it('should indicate there were custom templates only', function() {
            _controller({
                standardTemplates: [],
                customTemplates: ['a']
            });

            expect(_scope.noTemplates).toBe(false);

            expect(_scope.singleSetTemplates).toBe(true);
        });

        it('should indicate there were standard templates only', function() {
            _controller({
                standardTemplates: ['a'],
                customTemplates: []
            });

            expect(_scope.noTemplates).toBe(false);

            expect(_scope.singleSetTemplates).toBe(true);
        });
    });

    describe('selecting a csv file', function() {

        it('should send the parsed csv content to the server', function() {
            var postedData;

            _http.whenPOST('api/bulkcaseimport/importcases').respond(function() {
                postedData = JSON.parse(arguments[2]);
                return [200, {
                    result: {
                        result: 'success'
                    }
                }, {}];
            });

            _fileReaderPromise.resolve('file-content');

            _csvParserPromise.resolve('parsed-csv-content');

            _controller();

            _scope.onSelectFile([buildFile('a.csv', 'text/csv')]);

            _http.flush();

            expect(postedData.type).toBe('csv');
            expect(postedData.fileContent).toBe('parsed-csv-content');

            expect(_scope.status).toBe('success');
        });

        it('should display error from csv parser', function() {

            _fileReaderPromise.resolve('file-content');

            _csvParserPromise.reject([{
                message: 'invalid-parsed-csv-content'
            }]);

            _controller();

            _scope.onSelectFile([buildFile('a.csv', 'text/csv')]);

            _rootScope.$apply();

            expect(_scope.status).toBe('error');
            expect(_scope.errors[0].errorMessage).toMatch(/invalid-parsed-csv-content/);
        });
    });

    describe('selecting an xml file', function() {

        beforeEach(function() {
            _csvParserPromise.resolve('nothing!');
        });

        it('should not allow files other than xml (and csv)', function() {
            _controller();

            //spyOn(_rootScope, '$broadcast');
            _scope.onSelectFile([buildFile('a.txt')]);
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('should not allow xml files larger than 40 MB', function() {
            _controller();

            //spyOn(_rootScope, '$broadcast');
            _scope.onSelectFile([buildFile('a.xml', 'text/xml', 1024 * 1024 * 50)]);
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('should not allow csv files larger than 5 MB', function() {
            _controller();

            //spyOn(_rootScope, '$broadcast');
            _scope.onSelectFile([buildFile('a.csv', 'text/csv', 1024 * 1024 * 10)]);
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('should only allow one file', function() {
            _controller();

            //spyOn(_rootScope, '$broadcast');
            _scope.onSelectFile([buildFile(), buildFile()]);
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('should send the xml to the server', function() {
            var postedData;

            _http.whenPOST('api/bulkcaseimport/importcases').respond(function() {
                postedData = JSON.parse(arguments[2]);
                return [200, {
                    result: {
                        result: 'success'
                    }
                }, {}];
            });

            _fileReaderPromise.resolve('file-content');

            _controller();

            _scope.onSelectFile([buildFile('a.xml', 'text/xml')]);

            _http.flush();

            expect(postedData.type).toBe('cpaxml');
            expect(postedData.fileContent).toBe('file-content');

            expect(_scope.status).toBe('success');
        });

        it('should show a status bar while waiting for successful response', function() {
            _fileReaderPromise.resolve('file-content');
            _http.whenPOST('api/bulkcaseimport/importcases').respond(function() {
                return [404, {}, {}];
            });
            _controller();
            _scope.onSelectFile([buildFile()]);
            _http.flush();
            expect(_scope.status).toBe('error');
        });

        it('should relay errors from the server', function() {
            _http.whenPOST('api/bulkcaseimport/importcases').respond(function() {
                return [200, {
                    result: {
                        result: 'error',
                        errors: [{
                            errorMessage: 'message1'
                        }, {
                            errorMessage: 'message2'
                        }]
                    }
                }, {}];
            });

            _fileReaderPromise.resolve('file-content');

            _controller();
            _scope.onSelectFile([buildFile()]);
            _http.flush();
            expect(_scope.status).toBe('error');
            expect(_scope.errors[0].errorMessage).toBe('message1');
            expect(_scope.errors[1].errorMessage).toBe('message2');
        });

        it('should broadcast a success message', function() {
            _http.whenPOST('api/bulkcaseimport/importcases').respond(function() {
                return [200, {
                    result: {
                        result: 'success'
                    }
                }, {}];
            });

            _fileReaderPromise.resolve('file-content');

            _controller();
            _scope.onSelectFile([buildFile()]);
            //spyOn(_rootScope, '$broadcast');
            _http.flush();
            expect(notificationService.success).toHaveBeenCalled();
            expect(_scope.status).toBe('success');
        });

        it('should contain a link to monitor status page in the success message', function() {
            _http.whenPOST('api/bulkcaseimport/importcases').respond(function() {
                return [200, {
                    result: {
                        result: 'success'
                    }
                }, {}];
            });

            _fileReaderPromise.resolve('file-content');

            _controller();
            _scope.onSelectFile([buildFile()]);
            //spyOn(_rootScope, '$broadcast');
            _http.flush();
            expect(notificationService.success).toHaveBeenCalled();
            expect(_scope.status).toBe('success');
        });
    });
});