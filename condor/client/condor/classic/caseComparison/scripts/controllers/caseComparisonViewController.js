angular.module('Inprotech.CaseDataComparison')
    .controller('caseComparisonViewController', [
        '$rootScope', '$scope', 'http', 'url', 'comparisonDataSourceMap', 'legacyDataAdaptor', 'comparisonData', 'modalService', 'notificationService', 'comparisonConstantValues',
        function($rootScope, $scope, http, url, comparisonDataSourceMap, legacyDataAdaptor, comparisonData, modalService, notificationService, comparisonConstantValues) {
            'use strict';

            $scope.deCache = '';
            $scope.currentItem = null;
            $scope.errorView = 'caseCompareErrorView';
            $scope.mappingErrors = null;
            $scope.caseDetailsBaseUrl = url.inprotech('default.aspx?caseref=');
            comparisonData.getLanguages().then(function(data) {
                $scope.languages = data.data;
            });

            var openImageViewDialog = function(imageItem) {
                modalService.open('ImageView', $scope, {
                    imageItem: imageItem
                });
            };

            $scope.onRefresh = function() {
                $scope.refreshed = false;
                setTimeout(function() {
                    $scope.refreshed = true;
                    decache();
                }, 10);
            };

            $scope.caseImage = {
                viewCaseImage: function() {
                    $scope.caseImage.detailUrl = $scope.caseImage.getCaseImageUrl();
                    openImageViewDialog($scope.caseImage);
                },

                viewDownloadedImage: function() {
                    $scope.caseImage.detailUrl = url.api('img?source=filestore&id=' + encodeURIComponent($scope.viewData.caseImage.downloadedImageId));
                    openImageViewDialog($scope.caseImage);
                },

                getCaseImageUrl: function() {
                    if (!$scope.viewData.caseImage || !$scope.viewData.caseImage.caseImageIds.length) {
                        return null;
                    }

                    return url.api('img?source=inprotech.image&id=' + encodeURIComponent($scope.viewData.caseImage.caseImageIds[0]) + $scope.deCache);
                },

                getDownloadedImageUrl: function() {
                    var relevantImageId = comparisonDataSourceMap.systemCode($scope.dataSource) === comparisonConstantValues.dataSources.IpOneData ? $scope.viewData.caseImage.downloadedImageId :
                        $scope.viewData.caseImage.downloadedThumbnailId;

                    if (!$scope.viewData.caseImage || !relevantImageId) {
                        return null;
                    }

                    return url.api('img?source=filestore&id=' + encodeURIComponent(relevantImageId) + $scope.deCache);
                },

                getRefreshImageUrl: function() {
                    return url.api('img/refresh?notificationId=' + $scope.viewData.notificationId + $scope.deCache);
                },

                getDetailUrl: function() {
                    return $scope.caseImage.detailUrl;
                }
            };

            var decache = function() {
                $scope.deCache = '&decache=' + new Date().getTime();
            };

            function init(viewData, sourceData, id, systemCode) {
                $scope.refreshed = false;

                comparisonData.initData(legacyDataAdaptor.adapt(viewData), sourceData);

                decache();

                $scope.viewData = angular.extend(comparisonData.getData(), { notificationId: id, systemCode: systemCode });

                $scope.externalSystem = comparisonDataSourceMap.name($scope.dataSource);

                $scope.isTrademark = viewData.case && viewData.case.propertyTypeCode === 'T';

                var buildLink = function() {
                    if (!viewData['case'] || !viewData['case'].ref || !viewData['case'].ref.ourValue) {
                        return null;
                    }

                    return url.inprotech('default.aspx?caseref=' + encodeURIComponent(viewData['case'].ref.ourValue));
                };

                $scope.caseDetailsLink = buildLink();

                $scope.setMappingErrors();

                focus('caseComparisonDetailView');

                $rootScope.$broadcast('ComparisonDataLoaded');
            }

            $scope.setMappingErrors = function() {
                if (!$scope.viewData || !$scope.viewData.errors) {
                    return null;
                }
                $scope.mappingErrors = _.where($scope.viewData.errors, {
                    type: 'Mapping'
                });
            };

            $scope.setErrors = function(errors) {
                $scope.currentItem = errors;
                openErrorDetailsDialog(errors);
            };

            var openErrorDetailsDialog = function(errors) {
                modalService.open('ComparisonErrorDetails', $scope, {
                    item: function() { return errors; },
                    errorView: function() { return 'caseCompareErrorView'; }
                });
            };

            $scope.downloadLink = function(document) {
                return url.api('casecomparison/download?id=' + document.id);
            };

            $scope.showRefresh = function() {
                return comparisonDataSourceMap.systemCode($scope.dataSource) === comparisonConstantValues.dataSources.IpOneData;
            }

            $scope.documentStatus = function(d) {
                if (!$scope.viewData || d.status === 'Pending') {
                    return '';
                }

                if (d.status !== 'Downloaded') {
                    return d.status;
                }

                if (d.imported) {
                    return 'Attached';
                }

                if ($scope.dmsIntegrationEnabled) {
                    return 'NotSentToDms';
                }

                return $scope.viewData.updateable ? 'Attach' : 'NotAttached';
            };

            $scope.sendAllToDms = function() {
                _.each($scope.documentsViewData, function(d) {
                    if ((d.status === 'Downloaded' || d.status === 'FailedToSendToDms') && !d.imported) {
                        d.status = 'SendToDms';
                    }
                });

                http.post(url.api('dms/send/' + $scope.dataSource + '/case/' + $scope.caseId));
            };

            $scope.canSendAllToDms = function() {
                return $scope.dmsIntegrationEnabled && _.some($scope.documentsViewData, function(d) {
                    return (d.status === 'Downloaded' || d.status === 'FailedToSendToDms') && !d.imported;
                });
            };

            $scope.documentHasErrors = function(d) {
                return d.status === 'Failed' || d.status === 'FailedToSendToDms';
            };

            $scope.documentIsBeingSentToDms = function(d) {
                return d.status === 'SendToDms' || d.status === 'SendingToDms';
            };

            $scope.documentCanBeDownloaded = function(d) {
                // document can be downloaded if it does not have a download error
                // and it has not been sent to dms
                return d.status === 'Downloaded' || d.status === 'FailedToSendToDms';
            };

            function doComparison(evt, notification) {
                $scope.viewData = null;
                $scope.documentsViewData = null;
                $scope.dmsIntegrationEnabled = notification.dmsIntegrationEnabled;
                $scope.dataSource = notification.dataSource;
                $scope.caseId = notification.caseId;
                comparisonData.reset();

                var systemCode = comparisonDataSourceMap.systemCode(notification.dataSource);

                http.get(url.api('casecomparison/n/' + notification.notificationId + '/case/' + notification.caseId + '/' + systemCode))
                    .success(function(data) {
                        init(data.viewData, data.source, notification.notificationId, systemCode);
                    });

                /*Initialize documents separately since it is independent from saving changes to inprotech case.*/
                http.get(url.api('casecomparison/' + notification.dataSource + '/documents?caseId=' + notification.caseId))
                    .success(function(data) {
                        $scope.documentsViewData = data;
                    });
            }

            $scope.$on('case-comparison', doComparison);

            $scope.$on('rejected', doComparison);

            $scope.$on('case-comparison-updated', function() {
                notificationService.success('caseComparisonInbox.caseSaved');
                $scope.refreshed = false;
                decache();
                $scope.viewData = comparisonData.getData();
                $scope.$parent.detailViewTop = 0;
            });

            $scope.$on('case-comparison-error', function() {
                $scope.$parent.detailViewTop = 0;
            });

            $scope.initialInit = function(notification) {
                if (notification) {
                    doComparison(null, notification);
                }
            };
        }
    ]);