angular.module('Inprotech.CaseDataComparison')
    .controller('importDocumentController', [
        '$rootScope', '$scope', 'http', '$translate', 'url', 'documentToImport', 'notificationService', '$uibModalInstance',

        function($rootScope, $scope, http, $translate, url, documentToImport, notificationService, $uibModalInstance) {
            'use strict';
            var init = function(viewData) {

                $scope.imported = false;

                $scope.error = {};

                $scope.viewData = viewData;

                $scope.title = $translate.instant('caseComparison.idLblTitle', {
                    caseRef: viewData.caseRef
                });

                $scope.attachment = {
                    documentId: viewData.documentId,
                    caseId: viewData.caseId,
                    attachmentName: viewData.attachmentName,
                    activityDate: viewData.activityDate
                };

                $scope.maxCycle = null;

                $scope.setCycle = function(form) {
                    form.caseEvent.$setValidity('eventError', true);
                    if (!$scope.viewData.selectedEvent) {
                        $scope.attachment.cycle = null;
                    } else {
                        $scope.maxCycle = $scope.viewData.selectedEvent.cycle;
                        $scope.attachment.cycle = $scope.maxCycle;
                    }
                };

                $scope.cycleChanged = function(form) {
                    form.caseEvent.$setValidity('eventError', true);
                }

                $scope.save = function(form) {
                    form.$validate();
                    if (!form.$dirty || !form.$valid) {
                        return;
                    }

                    $scope.errors = {};

                    $scope.attachment.eventId = $scope.viewData.selectedEvent ? $scope.viewData.selectedEvent.eventId : null;
                    $scope.attachment.cycle = $scope.attachment.eventId ? $scope.attachment.cycle : null;
                    $scope.attachment.activityTypeId = $scope.viewData.selectedActivity.id;
                    $scope.attachment.categoryId = $scope.viewData.selectedCategory.id;
                    $scope.attachment.attachmentTypeId = $scope.viewData.selectedAttachmentType.id;

                    http.post(url.api('casecomparison/importDocument/save'), $scope.attachment)
                        .success(function(data) {
                            if (data.result === 'success') {
                                $scope.imported = true;
                                $uibModalInstance.close('success');
                            }

                            if (data.result === 'invalid-cycle') {
                                unableToComplete();
                                form.caseEvent.$setValidity('eventError', false);
                                form.$validate();
                            }
                        });

                };

                $scope.getEventError = function(caseEvent) {
                    if (caseEvent && !caseEvent.$valid && caseEvent.$error && caseEvent.$error.eventError) {
                        return $translate.instant('caseComparison.idLblInvalidCycle', {
                            maxCycle: $scope.maxCycle
                        });
                    }
                    return null;
                };

                $scope.dismiss = function(form) {
                    if (!form.$dirty) {
                        $uibModalInstance.close();
                        return;
                    }

                    notificationService.discard()
                        .then(function() {
                            $uibModalInstance.close();
                        });
                }
            };

            var unableToComplete = function() {
                notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.unsavedchanges'
                });
            }

            var initialize = function() {
                http.get(url.api('casecomparison/importDocument/' + documentToImport.caseId + '/' + documentToImport.document.id))
                    .success(function(data) {
                        init(data);
                    });
            }

            initialize();
        }
    ]);