(function() {
    'use strict';

    angular.module('inprotech.components.notification')
        .factory('notificationService', ['$rootScope', '$translate', '$q', 'modalService', 'scheduler', function($rootScope, $translate, $q, modalService, scheduler) {
            return {
                discard: function(options, scope) {
                    var o = options || {};

                    return modalService.open('DiscardChanges', scope, {
                        options: function() {
                            return o;
                        }
                    });
                },
                alert: function(options, scope) {
                    return modalService.open('Alert', scope, {
                        options: function() {
                            var o = options || {};

                            if (!o.message && o.errors instanceof Array && o.errors.length === 1) {
                                return {
                                    title: o.title || 'modal.unableToComplete',
                                    message: o.errors[0].message,
                                    okButton: o.okButton || 'button.ok'
                                };
                            }

                            if (o.errors) {
                                o.errors = o.errors.map(function(err) {
                                    if (angular.isString(err)) {
                                        return {
                                            message: err
                                        };
                                    }

                                    return err;
                                });
                            }

                            return {
                                title: o.title || 'modal.unableToComplete',
                                errors: o.errors,
                                message: o.message || 'modal.alert.message',
                                okButton: o.okButton || 'button.ok',
                                messageParams: o.messageParams,
                                actionMessage: o.actionMessage
                            };
                        }
                    });
                },
                confirm: function(options, scope) {
                    var o = options || {};
                    o.title = o.title || 'modal.confirmation.title';
                    o.cancel = o.cancel || 'modal.confirmation.no';
                    o.continue = o.continue || 'modal.confirmation.yes';

                    return modalService.open('Confirm', scope, {
                            options: function() {
                                return o;
                            }
                        },
                        options.templateUrl);
                },
                confirmDelete: function(options, scope) {
                    return modalService.open('ConfirmDelete', scope, {
                            options: function() {
                                return options;
                            }
                        },
                        options.templateUrl);
                },
                unsavedchanges: function(options, scope) {
                    return modalService.open('UnsavedChanges', scope, {
                        options: function() {
                            return options;
                        }
                    });
                },
                success: function(custom, interpolateParams, fadeOutTime) {
                    var message = custom || 'saveMessage';
                    $translate(message, interpolateParams).then(function(translated) {
                        scheduler.runOutsideZone(function() {
                            $.cpaFlashAlert(translated, fadeOutTime);
                        });
                    }, function(notTranslated) {
                        scheduler.runOutsideZone(function() {
                            $.cpaFlashAlert(notTranslated, fadeOutTime);
                        });
                    });
                },
                info: function(options, scope) {
                    var o = options || {};

                    return modalService.open('Info', scope, {
                        options: function() {
                            return {
                                title: o.title || 'modal.info.title',
                                message: o.message,
                                messageParams: o.messageParams,
                                sessionChkBox: o.sessionChkBox,
                                chkBoxLabel: o.chkBoxLabel
                            };
                        }
                    });
                },
                ieRequired: function(url) {
                    return modalService.openModal({
                        id: 'ieRequired',
                        controllerAs: 'vm',
                        url: url
                    });
                },
                empty: function() {
                    return $q.resolve();
                }
            };
        }]);
})();