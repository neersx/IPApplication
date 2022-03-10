describe('inprotech.components.login', function () {
    'use strict';

    var controller, modalService, scope, http;

    beforeEach(function () {
        module('inprotech.components.login');
        module(function ($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            test.mock('$state', 'stateMock');
            test.mock('hotkeys');
            http = test.mock('$http', 'httpMock');
        });
    });

    beforeEach(inject(function ($controller) {
        controller = function () {
            scope = {
                autoLogin: false,
                error: '',
                credentials: {
                    username: 'internal',
                    password: '',
                    invalidPassword: false
                }
            }
            var c = $controller('LoginController', {
                $rootScope: {
                    appContext: {
                        user: {
                            name: 'internal'
                        }
                    }
                },
                $scope: scope

            });
            return c;
        };
    }));

    describe('forms auth mode', function () {
        it('should initialise the controller and load the login window', function () {
            window.localStorage['signin'] = JSON.stringify({ authMode: 1 });
            controller();
            expect(http.post).not.toHaveBeenCalled();
        });

        it('should cancel the popup if auth cookie expired', function () {
            window.localStorage['signin'] = JSON.stringify({ authMode: 1 });
            controller();
            expect(http.post).not.toHaveBeenCalled();
            scope.credentials = {
                username: 'internal',
                password: 'password'
            }
            http.post.returnValue = {
                requiresTwoFactorAuthentication: true,
                status: 'codeRequired'
            };
            scope.submit();
            expect(modalService.cancel).toHaveBeenCalled();
        });
    });

    describe('sso adfs windows auto login mode', function () {
        beforeEach(function () {
            http.post = jasmine.createSpy().and.callFake(function () {
                return {
                    then: function (cb) {
                        return angular.extend({}, cb({
                            data: {
                                status: 'success'
                            }
                        }));
                    }
                }
            });
        });

        it('should initialise the controller and call http post for windows login', function () {
            window.localStorage['signin'] = JSON.stringify({ authMode: 2 });
            controller();

            expect(http.post).toHaveBeenCalledWith('../winAuth?extend=true', null, {
                handlesError: true
            });
            expect(modalService.close).toHaveBeenCalledWith('Login');
        });

        it('should initialise the controller and call http post for sso login', function () {
            window.localStorage['signin'] = JSON.stringify({ authMode: 3 });

            controller();

            expect(http.post).toHaveBeenCalledWith('api/signin/extendsso', null, {
                handlesError: true
            });
            expect(modalService.close).toHaveBeenCalledWith('Login');
        });

        it('should initialise the controller and call http post for adfs login', function () {
            window.localStorage['signin'] = JSON.stringify({ authMode: 4 });

            controller();

            expect(http.post).toHaveBeenCalledWith('api/signin/extendsso', null, {
                handlesError: true
            });
            expect(modalService.close).toHaveBeenCalledWith('Login');
        });
    });
});