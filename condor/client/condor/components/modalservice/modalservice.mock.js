angular.module('inprotech.mocks')
    .factory('modalServiceMock',
        function() {
            'use strict';

            var thenFunction, model;

            var modalServiceCallFinally = {
                finally: jasmine.createSpy('finallyFunction')
            };

            var modalServiceOpenReturn = {
                then: function() {
                    thenFunction = jasmine.createSpy('thenFunction');
                    return modalServiceCallFinally;
                }
            };

            var ModalServiceMock = {
                open: function() {
                    return modalServiceOpenReturn;
                },
                openModal: function() {
                    return modalServiceOpenReturn;
                },
                close: function() {
                    if (thenFunction) {
                        thenFunction(model);
                    }
                },
                register: function() {},
                getInstance: function() {
                    return jasmine.createSpyObj('modalInstance', ['close']);
                },
                cancel: function(obj) {
                    return {
                        catch: function(cb) {
                            cb(obj);
                        }
                    }
                }
            };

            test.spyOnAll(ModalServiceMock);
            spyOn(modalServiceOpenReturn, 'then').and.callThrough();

            return ModalServiceMock;
        });