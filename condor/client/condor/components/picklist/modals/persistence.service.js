(function() {
    'use strict';

    angular.module('inprotech.components.picklist')
        .service('persistenceService', ['$rootScope', '$translate', 'states', 'notificationService', function($rootScope, $translate, states, notificationService) {

            var seekConfirmation = function() {
                return notificationService.discard();
            };

            return {
                save: function(client, entry, hasInlineGrid, refresh) {
                    if (client.$invalid) {
                        notificationService.alert({
                            title: 'modal.unableToComplete',
                            message: 'modal.alert.unsavedchanges'
                        });
                        return;
                    }

                    var isInlineGrid = hasInlineGrid;

                    var afterSave = function(response) {
                        var message = 'modal.alert.unsavedchanges';
                        if (response.data.result === 'success' || response.data.result === 'confirmation') {
                            refresh(response.data);
                            return;
                        }

                        var instance = this;
                        message = '';
                        angular.forEach(response.data.errors, function(error) {
                            if (error.message === 'field.errors.notunique') {
                                message += $translate.instant('modal.alert.notUnique').replace('{value}', angular.element('<pre/>').text(instance[error.field]).html()) + '<br/>';
                                if (client[error.field]) {
                                    client[error.field].$setValidity(error.field, false);
                                }
                            } else if (error.displayMessage) {
                                message += $translate.instant(error.message) + '<br/>';
                                var maintenanceForm = isInlineGrid ? client['vm.form'] : client;
                                if (maintenanceForm[error.field]) {
                                    var validationId = error.customValidationMessage ? error.customValidationMessage : error.field;
                                    maintenanceForm[error.field].$setValidity(validationId, false);
                                }
                            } else if (error.message != null) {
                                message = null;
                            }
                        })


                        notificationService.alert({
                            title: 'modal.unableToComplete',
                            message: message,
                            errors: _.where(response.data.errors, {
                                field: null
                            })
                        });
                    };

                    entry
                        .$on('after-save', afterSave)
                        .$save();
                },

                delete: function(entry, success, back, serverParams, deleteMessage) {
                    notificationService
                        .confirmDelete({
                            message: deleteMessage
                        })
                        .then(function() {
                            entry
                                .$on('after-destroy', function(response) {
                                    if (response.data.result === 'success') {
                                        var callbackParams = {};
                                        if (entry.rerunSearch &&
                                            response.data.rerunSearch) {
                                            callbackParams.rerunSearch = true;
                                        }
                                        success(callbackParams);
                                        return;
                                    }

                                    if (response.data.result === 'confirmation') {
                                        var modalOptions = {
                                            message: response.data.message,
                                            cancel: entry.confirmDeleteCancel,
                                            continue: entry.confirmDeleteContinue
                                        };

                                        notificationService.confirm(modalOptions).then(function() {
                                            entry.withParams({
                                                confirm: true
                                            }).$destroy();
                                        }, back);
                                        return;
                                    }

                                    notificationService.alert({
                                        errors: response.data.errors,
                                        title: 'modal.unableToComplete'
                                    }).then(null, back);
                                });
                            if (serverParams) {
                                entry.withParams({
                                        deleteData: serverParams
                                    })
                                    .$destroy();
                            } else {
                                entry.withParams({
                                    confirm: false
                                }).$destroy();
                            }

                        }, function() {
                            back();
                            return;
                        });
                },

                abandon: function(entry, state, force, returnToNormal, inlineGridDirty, proceedToSave) {
                    // Remove the conidtion when removing Restmod completly
                    var dirty = (entry.session) ? (!force) : (entry.$dirty().length || inlineGridDirty || !force);
                    var addOrDuplicate = state === states.adding || state === states.duplicating;
                    var rerunSearch = entry.rerunSearch;

                    if (force || !addOrDuplicate && !dirty) {
                        returnToNormal(rerunSearch);
                        return;
                    }

                    seekConfirmation()
                        .then(function(result) {
                            if (result === 'Confirm') {
                                returnToNormal();
                            } else if (result === 'Save') {
                                proceedToSave();
                            }
                        });
                }
            };
        }]);
})();