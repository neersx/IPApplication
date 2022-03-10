angular.module('inprotech.components.typeahead').directive('iptTypeaheadMultiSelect', function($http, $timeout, $q, utils, typeaheadService) {
    'use strict';

    var defaultAutocompleteAddTemplate = 'condor/components/typeahead/multiselect-autocomplete-add.html';

    var defaultOptions = {
        keyProperty: 'id',
        displayProperty: 'value',
        addTagLabel: 'Add a New Tag',
        maxResultCount: 20,
        tagTemplate: 'condor/components/typeahead/multiselect-tag.html'
    };

    return {
        restrict: 'EA',
        scope: {
            items: '=',
            sourceUrl: '@',
            source: '=?',
            displayProperty: '@',
            keyProperty: '@',
            addUrl: '@',
            addTagLabel: '@',
            placeholder: '@',
            autocompleteTemplate: '@',
            maxResultCount: '@',
            tagTemplate: '@',
            isEdited: '=?',
            isSaved: '=?',
            isLoading: '=?',
            text: '=?',
            hasError: '=?',
            onSelectionChanged: '&',
            disabled: '@',
            autofocus: '@',
            required: '@'
        },
        templateUrl: 'condor/components/typeahead/multiselect.html',
        controller: function($scope, $element) {
            var hasFocus = false;
            var prevRequest = utils.cancellable();
            var hasResults = false;
            var lastResults = [];
            var internalAddTag;

            $scope.isLoading = false;

            utils.extendWithDefaults($scope, defaultOptions);

            if (!$scope.autocompleteTemplate) {
                if ($scope.addUrl) {
                    $scope.autocompleteTemplate = defaultAutocompleteAddTemplate;
                }
            }

            $element.on('setFocus', function() {
                setTimeout(function() {
                    $element.find('.input').focus();
                }, 10);
            });

            $element.on('keypress', '.input', function(evt) {
                if (evt.keyCode === 13) {
                    var val = $(evt.target).val();
                    if (val) {
                        evt.preventDefault();
                    }
                }
            });

            $scope.loadItems = function(q) {
                prevRequest.cancel();

                updateState(function() {
                    hasResults = false;
                    lastResults = [];
                    $scope.isLoading = true;
                });

                if (!$scope.sourceUrl && $scope.source) {
                    var deferred = $q.defer();
                    deferred.resolve($scope.source);
                    updateState(function() {
                        $scope.isLoading = false;
                    });

                    return deferred.promise;
                }

                debug('search.begin', q, $scope.sourceUrl);
                return $http.get($scope.sourceUrl, {
                        params: {
                            'q': q,
                            take: $scope.maxResultCount
                        },
                        timeout: prevRequest.promise
                    })
                    .then(function(response) {
                        var results = response.data;

                        if ($scope.addUrl) {
                            if (q.length > 0 && !_.find(_.union(response.data, $scope.items), function(data) {
                                    return q.toUpperCase() === (data[$scope.displayProperty] || '').toUpperCase();
                                })) {

                                var newItem = {
                                    addTagLabel: $scope.addTagLabel
                                };

                                newItem[$scope.keyProperty] = Math.random(); // ensure each new item to add has different id because tracking
                                newItem[$scope.displayProperty] = q;

                                results.push(newItem);
                            }
                        }

                        updateState(function() {
                            $scope.isLoading = false;
                        });

                        if (!$scope.text && q) {
                            results = [];
                        }

                        debug('search.response', results);

                        updateState(function() {
                            hasResults = results.length > 0;
                        });

                        lastResults = results;
                        return results;
                    })
                    .catch(function(rejection) {
                        if (rejection.status !== -1) {
                            updateState(function() {
                                $scope.isLoading = false;
                            });
                        }

                        updateState(function() {
                            hasResults = false;
                        });

                        lastResults = [];
                        return [];
                    });
            };

            $scope.addTag = function(t) {
                if (t.addTagLabel) {
                    if (!t[$scope.displayProperty]) {
                        return false;
                    }
                    $http.post($scope.addUrl, {
                        newTag: t[$scope.displayProperty]
                    }).then(function(id) {
                        t.id = id.data;
                    });
                }

                return true;
            };

            $scope.tagRemoved = function() {
                $scope.onSelectionChanged();
            };

            $scope.tagAdded = function() {
                $scope.onSelectionChanged();
            };

            $scope.showLoadingSpinner = function() {
                return $scope.isLoading;
            };

            $scope.initInputEvents = function(events) {
                events.on('input-focus', function() {
                    debug('input.focus');
                    updateState(function() {
                        hasFocus = true;
                    });
                });

                events.on('input-blur', function() {
                    debug('input.blur');

                    selectItem(internalAddTag);

                    updateState(function() {
                        hasFocus = false;
                    });
                });
            };

            $scope.initAutocompleteEvents = function(events) {
                internalAddTag = function(item) {
                    events.trigger('suggestion-add', item);
                    $scope.text = '';
                };

                events.on('input-preload', function() {
                    debug('input-preload');
                    updateState(function() {
                        $scope.isLoading = true;
                    });
                });

                events.on('suggestion-show', function(args) {
                    if (hasFocus) {
                        return;
                    }
                    debug('suggestion.show');

                    selectItem(internalAddTag);

                    args.reset();
                });

                events.on('suggestion-hide', function() {
                    debug('suggestion.hide');
                    validate();
                });
            };

            $scope.$watch('text', function(newVal, oldVal) {
                if (newVal === oldVal) {
                    return;
                }

                if (!newVal) {
                    validate();
                }
            });

            function updateState(cb) {
                cb();
                validate();
            }

            function validate() {
                if (hasFocus) {
                    if ($scope.isLoading || !$scope.text) {
                        $scope.hasError = false;
                    } else {
                        $scope.hasError = !!$scope.text && !hasResults;
                    }
                } else {
                    if ($scope.isLoading) {
                        $scope.hasError = false;
                    } else {
                        $scope.hasError = !!$scope.text;
                    }
                }
            }

            function debug() {
                var args = _.toArray(arguments);
                args.unshift('multi-typeahead');

                utils.debug.apply(utils, args);
            }

            function selectItem(add) {
                var item;
                if ($scope.addUrl) {
                    item = typeaheadService.findExactMatchItem(lastResults, function(itm) {
                        return itm.id != null;
                    });
                } else {
                    item = typeaheadService.findExactMatchItem(lastResults);
                }

                if (item) {
                    add(item);

                    lastResults = [];
                }
            }
        }
    };
});
