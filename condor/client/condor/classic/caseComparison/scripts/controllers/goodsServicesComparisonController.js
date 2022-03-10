angular.module('Inprotech.CaseDataComparison')
    .controller('goodsServicesComparisonController', [
        '$scope', 'modalService', 'comparisonData', 'comparisonDataSourceMap',
        function ($scope, modalService, comparisonData, comparisonDataSourceMap) {
            'use strict';

            $scope.toggleGoodsServicesSelection = function (item) {
                if (item.firstUsedDate && item.firstUsedDate.updateable) {
                    item.firstUsedDate.updated = item.class.updated;
                }
                if (item.firstUsedDateInCommerce && item.firstUsedDateInCommerce.updateable) {
                    item.firstUsedDateInCommerce.updated = item.class.updated;
                }
                if (item.text.updateable) {
                    item.text.updated = item.class.updated;
                }
            };

            $scope.showTextCompare = function (item) {
                $scope.currentItem = item;
                openGoodsServicesCompareDialog(item);
            };

            $scope.firstUsedDateFormat = function (d) {
                switch (d) {
                    case 'MonthYear':
                        return 'MMM-yyyy';
                    case 'Year':
                        return 'yyyy';
                    case 'P':
                        return 'd-MMM-yyyy';
                }
            };

            $scope.onOurLanguageChange = function (item) {
                if (item.class.ourValue === null) {
                    return;
                }
                var languageKey = item.language == null || item.language.ourValue === null ? '' : item.language.ourValue.key;
                comparisonData.getGoodsServicesText($scope.viewData.case.caseId, item.class.ourValue, languageKey).then(function (result) {
                    item.text.ourValue = result;
                    compareAndSetUpdatable(item);
                });
            }

            $scope.onTheirLanguageChange = function (item) {
                item.language.ourValue = item.language.theirValue;
                if (item.class.theirValue === null) {
                    return;
                }
                var languageCode = item.language == null || item.language.theirValue === null ? '' : item.language.theirValue.code;
                comparisonData.getImportedGoodsServicesText($scope.viewData.notificationId, item.class.theirValue, languageCode).then(function (result) {
                    item.text.theirValue = result;
                    compareAndSetUpdatable(item);
                });
            }

            var compareAndSetUpdatable = function (item) {
                item.text.different = item.text.ourValue !== item.text.theirValue;
                item.text.updateable = item.text.theirValue && item.text.theirValue.trim() !== '' && item.text.ourValue !== item.text.theirValue;
                item.class.updateable = item.text.updateable;
            };

            var openGoodsServicesCompareDialog = function (item) {
                modalService.open('GoodsServicesComparison', $scope, {
                    item: item
                });
            };

            $scope.$watch('dataSource', function () {
                $scope.showLanguage = $scope.dataSource ? comparisonDataSourceMap.showLanguage($scope.dataSource) : false;
                $scope.showFirstUseDate = $scope.dataSource ? comparisonDataSourceMap.showFirstUseDate($scope.dataSource) : false;
            });
        }
    ]);