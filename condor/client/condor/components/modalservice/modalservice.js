angular.module('inprotech.components.modal')
    .factory('modalService', function($uibModal, hotkeyService, $transitions, $uibModalStack) {
        'use strict';

        var registry = {};

        var service = {
            getRegistry: getRegistry,
            register: register,
            getInstance: getInstance,
            isOpen: isOpen,
            open: open,
            openModal: openModal,
            close: close,
            cancel: cancel,
            canOpen: canOpen
        };

        return service;

        function getRegistry() {
            return registry;
        }

        function register(id, controller, templateUrl, options) {
            if (angular.isUndefined(registry[id])) {
                registry[id] = {
                    controller: controller,
                    templateUrl: templateUrl,
                    isOpen: false,
                    instance: null,
                    options: angular.extend({}, {
                        backdrop: 'static',
                        backdropClass: 'centered'
                    }, options)
                };
                return true;
            } else {
                return false;
            }
        }

        function getInstance(id) {
            if (angular.isDefined(registry[id])) {
                return registry[id].instance;
            }
        }

        function isOpen(id) {
            return Boolean(registry[id] && registry[id].isOpen);
        }

        //legacy method. please use openModal instead.
        //scope is optional
        function open(id, scope, resolve, templateUrl, controllerAs) {
            // named parameters open method
            if (arguments.length === 1 && _.isObject(arguments[0])) {
                var args = id;

                id = args.id;
                scope = args.scope;
                templateUrl = args.templateUrl;
                controllerAs = args.controllerAs;

                resolve = {
                    options: function() {
                        return args.options;
                    }
                };
            }

            if (id.indexOf('.') !== -1) {
                var baseId = id.split('.')[0];

                if (angular.isDefined(registry[baseId]) && !registry[id]) {
                    registry[id] = angular.copy(registry[baseId]);
                    if (resolve && resolve.options && resolve.options.size) {
                        registry[id].options.size = resolve.options.size;
                    }
                }
            }

            if (angular.isDefined(registry[id]) && !registry[id].isOpen) {
                registry[id].instance = $uibModal.open(angular.extend({
                    controller: registry[id].controller,
                    templateUrl: templateUrl || registry[id].templateUrl,
                    scope: scope,
                    resolve: resolve,
                    controllerAs: controllerAs
                }, registry[id].options));

                registry[id].isOpen = true;

                // DR-20349 tabbing out of modal fix
                registry[id].instance.rendered.then(function() {
                    $('div.modal-dialog').append('<a href=\"\"></a>');
                });

                registry[id].instance.closed.then(function() {
                    registry[id].isOpen = false;
                    hotkeyService.pop();
                });

                registry[id].instance.opened.then(function() {
                    hotkeyService.push();
                });

                var unbind = $transitions.onStart({}, function() {
                    service.cancel(id);
                    unbind();
                });

                return registry[id].instance.result;
            }
        }

        //known args: id, templateUrl, controller, isSingleton, options
        function openModal(args) {
            if (args.id && !registry[args.id]) {
                throw new Error('cannot find modal registry');
            }

            var entry = args.id ? registry[args.id] : {};

            args = angular.extend({
                templateUrl: entry.templateUrl,
                controller: entry.controller,
                isSingleton: true, // for backward compatibility
                resolve: {
                    options: function() {
                        return args;
                    }
                }
            }, entry.options, args);

            if (args.isSingleton && entry.isOpen) {
                return;
            }

            var instance = $uibModal.open(angular.extend({}, args, {
                controller: 'ModalContainerController',
                templateUrl: null,
                template: '<div>'
            }));

            if (args.isSingleton) {
                entry.instance = instance;
                entry.isOpen = true;
            }

            instance.rendered.then(function() {
                $uibModalStack.getTop().value.modalDomEl.attr('id', args.id);
                $('div.modal-dialog').append('<a href=\"\"></a>');
            });

            instance.closed.then(function() {
                if (args.isSingleton) {
                    entry.isOpen = false;
                }

                hotkeyService.pop();
                unbind();
            });

            instance.opened.then(function() {
                hotkeyService.push();
            });

            var unbind = $transitions.onStart({}, function() {
                instance.dismiss();
                unbind();
            });

            return instance.result;
        }

        //warning: the close actually will call then method in promise
        //todo: review this implementation, if the intention is jumping out of the workflow, it should consider dismiss instead of close
        function close(id) {
            if (angular.isDefined(registry[id])) {
                if (registry[id].isOpen) {
                    registry[id].instance.close();
                }
            }
        }

        function cancel(id) {
            if (angular.isDefined(registry[id])) {
                if (registry[id].isOpen) {
                    registry[id].instance.dismiss();
                }
            }
        }

        function canOpen(withModal) {
            return (_.filter(Object.keys(registry), function(modal) {
                return withModal !== modal && registry[modal].isOpen;
            })).length < 1 && (angular.isUndefined(withModal) || (angular.isDefined(withModal) && this.isOpen(withModal)));
        }
    });
