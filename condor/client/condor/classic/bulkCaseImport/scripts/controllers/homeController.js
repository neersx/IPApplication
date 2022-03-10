angular.module('Inprotech.BulkCaseImport')
    .controller('homeController', [
        '$scope', 'http', 'notificationService', 'fileReader', 'csvParser', '$translate', 'url', 'viewInitialiser',
        function ($scope, http, notificationService, fileReader, csvParser, $translate, url, viewInitialiser) {
            'use strict';

            var templates = function (templates, type) {
                return _.map(templates || [], function (item) {
                    return {
                        link: 'api/bulkcaseimport/template?type=' + type + '&name=' + encodeURIComponent(item),
                        name: item
                    };
                });
            };

            $scope.standardTemplates = templates(viewInitialiser.viewData.standardTemplates, 'standard');
            $scope.customTemplates = templates(viewInitialiser.viewData.customTemplates, 'custom');
            $scope.noTemplates = $scope.standardTemplates.length === 0 && $scope.customTemplates.length === 0;
            $scope.singleSetTemplates = ($scope.standardTemplates.length === 0 && $scope.customTemplates.length > 0) || ($scope.standardTemplates.length > 0 && $scope.customTemplates.length === 0);

            $scope.status = 'idle';
            $scope.fileName = '';

            var onComplete = function (response) {

                $scope.errors = [];

                if (!response.errors && response.result !== 'exception') {
                    notificationService.success($translate.instant('bulkCaseImport.bciSuccessMessage', {
                        identifier: response.requestIdentifier
                    }));
                    $scope.status = 'success';
                    return;
                }

                switch (response.result) {
                    case 'invalid-input':
                        $scope.errorHeading = $translate.instant('bulkCaseImport.bciErrorHeadingInvalidInput', {
                            fileName: $scope.fileName
                        });
                        break;
                    case 'blocked':
                        $scope.errorHeading = $translate.instant('bulkCaseImport.bciErrorWaitExportInProgress');
                        break;
                    case 'exception':
                        $scope.errorHeading = $translate.instant('bulkCaseImport.bciErrorServersideException', {
                            fileName: $scope.fileName
                        });
                        break;
                }

                $scope.status = 'error';
                $scope.errors = response.errors;
            };

            $scope.onSelectFile = function (files) {

                beginProcessing();

                if (!files || files.length === 0) {
                    throw 'at least one file should be specified';
                }

                if (files.length > 1) {
                    showError($translate.instant('bulkCaseImport.bciErrorMoreThanOneFileSelected'));
                    return;
                }

                var file = files[0];
                if (!isXml(file) && !isCsv(file)) {
                    showError($translate.instant('bulkCaseImport.bciErrorInvalidFileType'));
                    return;
                }

                var MB = 1024 * 1024;
                if (isXml(file) && (file.size > 40 * MB)) {
                    showError($translate.instant('bulkCaseImport.bciErrorInvalidFileSizeXML'));
                    return;
                }

                if (isCsv(file) && (file.size > 5 * MB)) {
                    showError($translate.instant('bulkCaseImport.bciErrorInvalidFileSizeCSV'));
                    return;
                }

                fileReader.readAsText(file).then(function (content) {
                    if (isCsv(file)) {
                        csvParser.parse(content)
                            .then(function (parsed) {
                                post('csv', file.name, parsed);
                            })
                            .catch(function (errors) {
                                $scope.fileName = file.name;
                                onComplete({
                                    result: 'invalid-input',
                                    errors: _.map(errors, function (e) {
                                        var m = e.message;
                                        if (e.line && e.index) {
                                            m = $translate.instant('bulkCaseImport.bciErrorCsvParser', {
                                                fileName: e.message,
                                                line: e.line,
                                                index: e.index
                                            });
                                        }
                                        return {
                                            errorMessage: m
                                        };
                                    })
                                });
                            });
                    } else {
                        post('cpaxml', file.name, content);
                    }
                });
            };

            var post = function (type, fileName, fileContent) {
                $scope.fileName = fileName;
                $scope.status = 'upload';
                http.post(url.api('bulkcaseimport/importcases'), {
                    'type': type,
                    'fileName': $scope.fileName,
                    'fileContent': fileContent
                })
                    .success(function (response) {
                        onComplete(response);
                    })
                    .catch(function () {
                        onComplete({
                            result: 'exception'
                        });
                    });
            };

            var beginProcessing = function () {
                $scope.errors = [];
                $scope.status = 'initialcheck';
            };

            var showError = function (message) {
                notificationService.alert({
                    message: message
                });
                $scope.status = 'idle';
            };

            var isXml = function (file) {
                return file.name.match(/.*\.xml/gi);
            };

            var isCsv = function (file) {
                return file.name.match(/.*\.csv/gi);
            };
        }
    ]);