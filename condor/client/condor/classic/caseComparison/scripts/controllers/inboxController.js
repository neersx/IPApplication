angular.module('Inprotech.CaseDataComparison')
    .controller('inboxController', [
        '$scope', 'http', 'url', 'comparisonDataSourceMap', 'viewInitialiser', 'notificationsService', 'inboxState', '$q', '$stateParams', 'focus', 

        function($scope, http, url, comparisonDataSourceMap, viewInitialiser, notificationsService, inboxState, $q, $stateParams, focus) {
            'use strict';

            var allDataSourcesSelected = true;
            var isSearchPerformed = false;

            $scope.reloadedData = true;
            $scope.notifications = [];
            $scope.dataSources = [];
            $scope.hasMore = true;
            $scope.filterParams = {
                dataSources: {},
                searchText: '',
                since: ''
            };

            var init = function() {
                $scope.canUpdateCase = viewInitialiser.viewData.canUpdateCase;
                $scope.isForSelectedCasesOnly = notificationsService.forSelectedCases();
                $scope.isFilteredExecution = notificationsService.isFilteredExecution();
                if ($scope.isForSelectedCasesOnly || $scope.isFilteredExecution) {
                    _.extend($scope.filterParams, {
                        includeReviewed: true,
                        includeErrors: true,
                        includeRejected: true
                    });
                } else {
                    _.extend($scope.filterParams, {
                        includeReviewed: false,
                        includeErrors: false,
                        includeRejected: false
                    });
                }

                if ($stateParams.restore) {
                    var savedState = inboxState.pop();
                    if (savedState) {
                        $scope.notifications = savedState.notifications;
                        setDataSources(savedState.dataSources);
                        allDataSourcesSelected = _.all($scope.dataSources, { isSelected: false });
                        $scope.hasMore = savedState.hasMore;
                        _.extend($scope.filterParams, savedState.filters);

                        var indexToSelect = _.findIndex($scope.notifications, { notificationId: savedState.notificationIdToSelect });

                        if (indexToSelect >= 0 && $scope.notifications.length > indexToSelect) {
                            $scope.initialDetailView = $scope.notifications[indexToSelect];
                        }
                    } else {
                        $scope.loadData();
                    }
                } else {
                    $scope.loadData();
                }
           }

            $scope.isSelected = function(dataSource) {
                var selectedSource = _.findWhere($scope.dataSources, dataSource);
                return selectedSource.isSelected;
            };

            $scope.showView = function(notification) {
                $scope.detailView = notification;

                if (notification) {
                    notification.dmsIntegrationEnabled = getdmsIntegrationEnabled(notification.dataSource);
                    $scope.$broadcast(notification.type, notification);
                } else {
                    $scope.$broadcast('error', null);
                }

                if (notification) {
                    var index = _.findIndex($scope.notifications, $scope.detailView);
                    if ($scope.hasMore && (index + 2 > $scope.notifications.length)) {
                        $scope.loadData();
                    }
                }
            };

            $scope.$on('case-match-rejection', function(evt, data) {
                var index = _.findIndex($scope.notifications, $scope.detailView);
                $scope.notifications[index] = data;
                $scope.showView(null);

                var navigated = navigateNextIf(function() {
                    return !$scope.filterParams.includeRejected;
                });

                if (!navigated) {
                    $scope.showView(data);
                }
            });

            $scope.$on('case-match-rejection-reversed', function(evt, data) {
                var index = _.findIndex($scope.notifications, $scope.detailView);
                $scope.notifications[index] = data;
                $scope.showView(data);
            });

            $scope.$watch('detailView.isReviewed', function() {
                return navigateNextIf(function() {
                    return $scope.detailView && $scope.detailView.isReviewed && !$scope.filterParams.includeReviewed;
                });
            });

            var navigateNextIf = function(predicate) {
                var index = _.findIndex($scope.notifications, $scope.detailView);

                if (predicate()) {
                    var nextNotification = null;

                    if (index + 1 <= $scope.notifications.length) {
                        nextNotification = $scope.notifications[index + 1];
                    }

                    $scope.showView(nextNotification);

                    $scope.notifications.splice(index, 1);

                    return true;
                }

                return false;
            };

            $scope.filteringChanged = function(dataSource) {
                var selectedSource = _.findWhere($scope.dataSources, dataSource);
                selectedSource.isSelected = !(selectedSource.isSelected);

                var count = _.countBy($scope.dataSources, function(n) {
                    return n.isSelected === true;
                });

                allDataSourcesSelected = ((count.true && count.true === $scope.dataSources.length) || (count.false && count.false === $scope.dataSources.length));

                reloadData();
            };

            $scope.inclusionChanged = function() {
                reloadData();
            };

            $scope.search = function() {
                if (!$scope.filterParams.searchText) {
                    return;
                }

                isSearchPerformed = true;
                reloadData();
            };

            $scope.$on('ComparisonDataLoaded', function() {
                if (isSearchPerformed) {
                    setFocusOnSearchText();
                }
            });

            var setFocusOnSearchText = function() {
                focus('txtSearchText');
                isSearchPerformed = false;
            };

            var setDataSources = function(dataSources) {
                if (_.isEmpty($scope.dataSources)) {
                    $scope.dataSources.push.apply($scope.dataSources, dataSources);
                    return true;
                }
                return false;
            };

            $scope.cancelSearch = function() {
                if ($scope.filterParams.searchText !== '') {
                    $scope.filterParams.searchText = '';
                }
                reloadData();
            };

            $scope.loadData = function() {
                $scope.status = 'loading';
                $scope.filterParams.dataSources = getSelectedSourceIds();

                var isForceLoad = !$scope.filterParams.since;

                notificationsService
                    .get($scope.filterParams)
                    .then(function(res) {
                        if (!res) {
                            if (isForceLoad) {
                                $scope.notifications.splice(0, $scope.notifications.length);
                            }
                            return;
                        }

                        if (setDataSources(res.dataSources)) {
                            setInitialDataSourceSelection();
                        }

                        if (isForceLoad) {
                            $scope.notifications.splice(0, $scope.notifications.length);
                        }

                        $scope.notifications.push.apply($scope.notifications, res.notifications);
                        $scope.hasMore = res.hasMore;

                        if ($scope.notifications.length > 0) {
                            if ($scope.isForSelectedCasesOnly) {
                                $scope.filterParams.since = _.last($scope.notifications).caseId;
                            } else if($scope.isFilteredExecution) {
                                $scope.filterParams.since = _.last($scope.notifications).notificationId;
                            } else {
                                $scope.filterParams.since = _.last($scope.notifications).date;
                            }
                        }

                        if (isForceLoad && !_.isEmpty($scope.notifications)) {
                            var firstRecord = _.first($scope.notifications);
                            $scope.showView(firstRecord);
                            if ((firstRecord.type === 'new-case' || firstRecord.type === 'error') && isSearchPerformed) {
                                setFocusOnSearchText();
                            }
                        } else if (isForceLoad && isSearchPerformed) {
                            setFocusOnSearchText();
                        }
                    })
                    .finally(function() {
                        $scope.status = 'loaded';
                    });
            };

            $scope.onNavigateToDuplicateView = function() {
                return $q.when(inboxState.save($scope.notifications, $scope.dataSources, $scope.filterParams, $scope.detailView, $scope.hasMore));
            };

            var setInitialDataSourceSelection = function() {
                if ($scope.dataSources) {
                    _.each($scope.dataSources, function(source) {
                        source.isSelected = false;
                    });
                }
            };

            $scope.getSourceName = function(sourceId) {
                return comparisonDataSourceMap.name(sourceId);
            };

            var getSelectedSourceIds = function() {
                if ($scope.dataSources) {
                    if (allDataSourcesSelected) {
                        return _.pluck($scope.dataSources, 'id');
                    }

                    return _.pluck(_.where($scope.dataSources, {
                        isSelected: true
                    }), 'id');
                }

                return null;
            };

            var getdmsIntegrationEnabled = function(dsName) {
                var dataSource = _.find($scope.dataSources, function(ds) {
                    return ds.id === dsName;
                });
                return dataSource && dataSource.dmsIntegrationEnabled;
            };

            var reloadData = function() {
                if ($scope.detailView) {
                    $scope.showView(null);
                }

                $scope.filterParams.since = '';

                $scope.loadData();
            };

            $scope.status = 'loaded';

            init();

            $scope.isLoaded = function() {
                return $scope.status === 'loaded';
            };
        }
    ]);