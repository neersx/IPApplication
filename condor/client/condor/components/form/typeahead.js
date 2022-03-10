angular.module('inprotech.components.form').directive('ipTypeahead', function($http, utils, picklistService, typeaheadConfig, formControlHelper) {
    'use strict';
    var SearchDebounce = 200;

    return {
        require: ['ngModel', '?^ipForm'],
        scope: { //todo: use isolate scope, controllerAs
            config: '@?',
            // placeholder: static
            // keyField: static,
            // codeField: static,
            // textField: static,
            // tagField: static,
            // apiUrl: static,
            // restmodApi: static,
            // maxResults: static,
            // itemTemplateUrl: static,
            // picklistCanMaintain: static,
            picklistTemplateUrl: '@?',
            editUriState: '@?',
            label: '@?',
            hideLabel: '@?',
            // picklistDisplayName: static,
            // picklistColumns: expression
            // extendQuery: expression
            // externalScope: expression
            state: '=?',
            text: '=?',
            loading: '=?'
        },
        templateUrl: function(element, attrs) {
            if (attrs.multiselect != null) {
                return 'condor/components/form/typeahead-multiselect.html';
            }
            return 'condor/components/form/typeahead.html';
        },
        controller: function($scope, $attrs) {
            var options = typeaheadConfig.resolve($attrs, $scope);
            angular.extend($scope, options);
        },
        link: function(scope, element, attrs, ctrls) {
            var multiselect = attrs.hasOwnProperty('multiselect');
            var prevRequest = utils.cancellable();
            var extendQuery = attrs.extendQuery && scope.$parent.$eval(attrs.extendQuery) || scope.extendQuery || _.identity;
            var externalScope = attrs.externalScope && scope.$parent.$eval(attrs.externalScope) || null;
            var ngModelCtrl = ctrls[0];
            var formCtrl = ctrls[1];
            var listClicked = false;
            var itemArray = [];
            scope.state = 'idle';
            scope.results = null; //null: hide autocompelte, []: show no results
            scope.openModal = openModal;
            scope.onListClicked = onListClicked;
            scope.multipick = attrs.hasOwnProperty('multipick');
            scope.uid = scope.$id;

            ngModelCtrl.$loading = false;

            formControlHelper.init({
                scope: scope,
                className: 'ip-typeahead',
                inputSelector: 'input.typeahead',
                element: element,
                attrs: attrs,
                ngModelCtrl: ngModelCtrl,
                formCtrl: formCtrl,
                customRender: true,
                customChange: true,
                onReset: function() {
                    scope.text = '';
                    changeState('idle');
                }
            });

            ngModelCtrl.$setText = function(str) {
                scope.text = str;
            };

            if (multiselect) {
                scope.getSelectedItems = function() {
                    if (_.isArray(ngModelCtrl.$modelValue)) {
                        itemArray = ngModelCtrl.$modelValue;
                    } else {
                        itemArray = _.toArray(ngModelCtrl.$modelValue);
                    }
                    return itemArray;
                };

                scope.$watch(function() {
                    return ngModelCtrl.$modelValue;
                }, function() {
                    adjustMultiSelectInputWidth();
                });

                $(window).on('resize', adjustMultiSelectInputWidth);

                scope.$on('$destroy', function() {
                    $(window).off('resize', adjustMultiSelectInputWidth);
                });
            }

            if (!multiselect) {
                if (ngModelCtrl) {
                    ngModelCtrl.$render = function() {
                        var item = ngModelCtrl.$viewValue;
                        if (item && item[scope.textField] ) {
                            var value = "";
                            if(scope.displayCodeWithText && item[scope.codeField] != null && item[scope.codeField] !== '') {
                                value = "(" + item[scope.codeField] + ") ";                        
                            }
                            scope.text = value + item[scope.textField];
                        } else {
                            scope.text = '';
                        }
                    };
                }
            }

            scope.textChange = function() {
                // if mode is single select and text field is blank, set ng-model to null
                if (!scope.text && !multiselect) {
                    ngModelCtrl.$setViewValue(null);
                }

                executeAction({
                    type: 'text.change',
                    value: scope.text
                });
            };

            scope.onTagsKeydown = function($event) {
                if (multiselect) {
                    switch ($event.keyCode) {
                        case 37: // left
                            move(-1, false);
                            break;
                        case 39: // right
                            move(1, false);
                            break;
                        case 8: // backspace
                            if (!scope.text) {
                                move(-1, true);
                            }
                            break;
                        case 46: // del
                            if (!scope.text) {
                                move(1, true);
                            }
                            break;
                        default:
                            clearSelectedTag();
                            break;
                    }
                }
            }

            scope.keydown = function($event) {
                switch ($event.keyCode) {
                    case 40:
                        executeAction({
                            type: 'key.down'
                        });
                        break;
                    case 27:
                        executeAction({
                            type: 'key.esc'
                        });
                        break;
                    case 113:
                        scope.openModal();
                        break;
                }
            };

            scope.onSelected = function(index) {
                if (itemArray && itemArray.length > 0) {
                    if (itemArray.length === 1) {
                        itemArray[0].isTagSelected = true;
                    } else {
                        for (var i = 0; i < itemArray.length; i++) {
                            itemArray[i].isTagSelected = (index === i);
                        }
                    }
                }
            }

            function clearSelectedTag() {
                if (itemArray && itemArray.length > 0) {
                    for (var i = itemArray.length - 1; i >= 0; i--) {
                        itemArray[i].isTagSelected = false;
                    }
                }
            }

            function move(direction, deleteCurrent) {
                if (itemArray && itemArray.length > 0) {
                    if (itemArray.length === 1) {
                        if (deleteCurrent === true && itemArray[0].isTagSelected === true) {
                            itemArray.splice(0, 1);
                            return;
                        }
                        itemArray[0].isTagSelected = true;
                    } else {
                        if (direction === 1) {
                            moveNext(deleteCurrent);
                        } else if (direction === -1) {
                            movePrevious(deleteCurrent);
                        }
                    }
                }
            }

            function moveNext(deleteCurrent) {
                for (var i = 0; i < itemArray.length; i++) {
                    if (itemArray[i].isTagSelected === true) {
                        if (deleteCurrent) {
                            if (i === itemArray.length - 1) {
                                itemArray[i - 1].isTagSelected = true;
                            } else {
                                itemArray[i + 1].isTagSelected = true;
                            }
                            itemArray.splice(i, 1);
                            return;
                        } else {
                            if (i === itemArray.length - 1) {
                                itemArray[0].isTagSelected = true;
                            } else {
                                itemArray[i + 1].isTagSelected = true;
                            }
                            itemArray[i].isTagSelected = false;
                            return;
                        }
                    }
                }
                itemArray[0].isTagSelected = true;
            }

            function movePrevious(deleteCurrent) {
                for (var i = itemArray.length - 1; i >= 0; i--) {
                    if (itemArray[i].isTagSelected === true) {
                        if (deleteCurrent) {
                            if (i === 0) {
                                itemArray[i + 1].isTagSelected = true;
                            } else {
                                itemArray[i - 1].isTagSelected = true;
                            }
                            itemArray.splice(i, 1);
                            return;
                        } else {
                            if (i === 0) {
                                itemArray[itemArray.length - 1].isTagSelected = true;
                            } else {
                                itemArray[i - 1].isTagSelected = true;
                            }
                            itemArray[i].isTagSelected = false;
                            return;
                        }
                    }
                }
                itemArray[itemArray.length - 1].isTagSelected = true;
            }

            scope.blur = function($event) {
                if (listClicked === true) {
                    // Only triggers in IE, due to the IE scroll bar handling
                    listClicked = false;
                    $event.target.focus();
                } else {
                    ngModelCtrl.$setTouched();
                    executeAction({
                        type: 'input.blur'
                    });
                }
            };

            scope.select = function(item) {
                executeAction({
                    type: 'item.select',
                    value: item
                });
            };

            scope.removeItem = function(item) {
                if (scope.disabled) {
                    return;
                }

                var selectedItems = scope.getSelectedItems();
                var newItems = _.without(selectedItems, item);

                ngModelCtrl.$setViewValue(newItems);
            };

            scope.showError = function() {
                if (scope.state === 'invalid') {
                    return true;
                }

                if (scope.state === 'idle') {
                    if (ngModelCtrl.$error.required && !ngModelCtrl.$touched) {
                        return false;
                    }

                    return ngModelCtrl.$invalid;
                }

                return false;
            };

            element.on('keydown', 'input.typeahead', function($event) {
                var autocomplete = scope.linkedAutocomplete.data('autocomplete');
                if ($event.keyCode === 40) {
                    // down
                    if (autocomplete) {
                        autocomplete.next();
                    }

                    $event.preventDefault();
                } else if ($event.keyCode === 38) {
                    // up
                    if (autocomplete) {
                        autocomplete.prev();
                    }

                    $event.preventDefault();
                } else if ($event.keyCode === 13) {
                    // enter
                    if (autocomplete && autocomplete.hasItems()) {
                        scope.$apply(function() {
                            autocomplete.select();
                        });

                        $event.preventDefault();
                    }
                } else if ($event.keyCode === 9) {
                    // tab
                    if (autocomplete) {
                        var r = scope.$apply(function() {
                            return autocomplete.select();
                        });

                        if (r) {
                            $event.preventDefault();
                        }
                    }
                }
            });

            var doSearch = _.debounce(function(value) {
                prevRequest.cancel();
                value = value == null ? '' : value;

                if (scope.state === 'idle') { //avoid unecessary search running when text field is blank
                    return;
                }

                var params = extendQuery({
                    search: value,
                    params: JSON.stringify({
                        skip: 0,
                        take: scope.maxResults
                    })
                });

                (function(originalSearchValue) {
                    $http.get(scope.apiUrl, {
                        params: params,
                        timeout: prevRequest.promise
                    }).then(function(response) {
                        if (originalSearchValue !== (scope.text || '')) {
                            return;
                        }

                        var results = response.data.data || response.data || [];
                        var total = response.data.pagination ? response.data.pagination.total : results.length;

                        if (multiselect) {
                            markSelected(results);
                        } else {
                            if (results.length)
                                results[0].$selected = true;
                        }

                        //remove already selected value, when new search have none/multiple items                               
                        if (!multiselect) {
                            ngModelCtrl.$setViewValue(null);
                        }

                        executeAction({
                            type: 'search.response',
                            value: {
                                data: results,
                                total: total
                            }
                        });
                    }).catch(function(rejection) {
                        if (rejection.status === -1) {
                            return;
                        }

                        ngModelCtrl.$setValidity('invalidentry', false);
                        changeState('invalid');
                    });
                })(value);
            }, SearchDebounce);

            function search(value, force) {
                if (value && itemSelected() &&
                    scope.state === 'cancelled') {
                    changeState('idle');
                    return;
                }
                if (!value && !force) {
                    prevRequest.cancel();
                    changeState('idle');
                    return;
                }
                setLoading(true);
                changeState('loading');
                doSearch(value);
            }

            //warning: state machine
            function executeAction(action) {
                if (scope.disabled) {
                    return;
                }

                utils.debug('state.transition', scope.state, action.type, action);

                switch (scope.state) {
                    case 'idle':
                        switch (action.type) {
                            case 'text.change':
                                search(scope.text);
                                break;
                            case 'key.down':
                                search(scope.text, true);
                                break;
                        }
                        break;
                    case 'loading':
                        switch (action.type) {
                            case 'text.change':
                                search(scope.text);
                                break;
                            case 'search.response':
                                setLoading(false);
                                var hasFocus = element.find('.typeahead').is(':focus');
                                var results = action.value.data;
                                var total = action.value.total;

                                if (hasFocus) {
                                    changeState('loaded');
                                    scope.results = results;
                                    scope.total = total;
                                } else {
                                    handleBlur(results);
                                }
                                break;
                            case 'key.esc':
                                setLoading(false);
                                changeState('cancelled');
                                break;
                            case 'input.blur':
                                setLoading(false);
                                scope.results = null;
                                break;
                        }
                        break;
                    case 'loaded':
                        switch (action.type) {
                            case 'text.change':
                                search(scope.text);
                                break;
                            case 'item.select':
                                selectItem(action.value);
                                changeState('idle');
                                break;
                            case 'key.esc':
                                changeState('cancelled');
                                break;
                            case 'input.blur':
                                if (!scope.text) {
                                    changeState('idle');
                                } else {
                                    handleBlur(scope.results);
                                }
                                break;
                        }

                        break;
                    case 'cancelled':
                        switch (action.type) {
                            case 'text.change':
                            case 'key.down':
                            case 'input.blur':
                                search(scope.text);
                                break;
                        }
                        break;
                    case 'invalid':
                        switch (action.type) {
                            case 'text.change':
                            case 'key.down':
                                search(scope.text);
                                break;
                        }
                        break;
                    case 'modal':
                        switch (action.type) {
                            case 'modal.cancel':
                                changeState('cancelled');
                                element.find('input.typeahead').focus();
                                break;
                            case 'modal.select':
                                selectItem(action.value);
                                element.find('input.typeahead').focus();
                                changeState('idle');
                                break;
                        }
                        break;
                }
            }

            function handleBlur(results) {
                if (results.length) {
                    changeState('idle');
                    selectItem(results[0]);
                } else {
                    ngModelCtrl.$setValidity('invalidentry', false);
                    changeState('invalid');
                }
                listClicked = false;
            }

            function changeState(state) {
                switch (state) {
                    case 'idle':
                        ngModelCtrl.$setValidity('invalidentry', null);
                        scope.results = null;
                        scope.state = state;
                        setLoading(false);
                        break;
                    case 'cancelled':
                        scope.results = null;
                        scope.state = state;
                        if (!scope.text) {
                            scope.state = 'idle';
                        }
                        break;
                    case 'loading':
                        scope.state = state;
                        break;
                    case 'loaded':
                        scope.state = state;
                        break;
                    case 'invalid':
                        scope.results = null;
                        scope.state = state;
                        break;
                    case 'modal':
                        scope.results = null;
                        scope.state = state;
                        break;
                }
            }

            function selectItem(item) {
                if (multiselect) {
                    if (Object.prototype.toString.call(item) === '[object Array]') {
                        ngModelCtrl.$setViewValue(item); // from pick list
                    } else {
                        addItem(item); // from type-ahead
                    }
                    scope.text = '';
                } else {
                    var k1 = getKeyValue(ngModelCtrl.$viewValue);
                    var k2 = getKeyValue(item);

                    if (k1 !== k2) {
                        ngModelCtrl.$setViewValue(item);
                    }

                    // always updating text
                    scope.text = getDisplayValue(item);
                }
                scope.results = null;
            }

            function itemSelected() {
                if (multiselect) {
                    return _.any(scope.getSelectedItems());
                }

                return getKeyValue(ngModelCtrl.$viewValue);
            }

            function getDisplayValue(item) {
                if(scope.displayCodeWithText && item) {
                    var value = "";
                    if(item[scope.codeField] != null && item[scope.codeField] !== '') {
                        value = "(" + item[scope.codeField] + ") ";                        
                    }
                    return value + item[scope.textField] || null
                }
                return item && item[scope.textField] || null;
            }

            function getKeyValue(item) {
                var itemKeyValue = item && item[scope.keyField];
                return angular.isUndefined(itemKeyValue) ? null : itemKeyValue;
            }

            function addItem(item) {
                var selectedItems = scope.getSelectedItems() || [];
                var exists = _.some(selectedItems, function(a) {
                    return item[scope.keyField] === a[scope.keyField];
                });

                if (!exists) {
                    var newItems = selectedItems.slice(0);
                    newItems.push(item);
                    ngModelCtrl.$setViewValue(newItems);
                }
            }

            function onListClicked(val) {
                listClicked = val;
            }

            function openModal() {
                if (scope.disabled) {
                    return;
                }

                changeState('modal');

                var columns;

                if (scope.picklistColumns) {
                    columns = scope.$parent.$eval(scope.picklistColumns);
                }

                picklistService.openModal(scope, {
                    type: scope.restmodApi || scope.apiUriName,
                    displayName: scope.picklistDisplayName,
                    apiUrl: scope.apiUrl,
                    apiUriName: scope.apiUriName,
                    templateUrl: scope.picklistTemplateUrl,
                    multipick: scope.multipick,
                    searchValue: scope.text,
                    selectedItems: scope.getSelectedItems ? scope.getSelectedItems() : null,
                    canMaintain: scope.$parent.$eval(scope.picklistCanMaintain),
                    size: scope.size,
                    columnMenu: scope.columnMenu || false,
                    columns: columns,
                    extendQuery: extendQuery,
                    externalScope: externalScope,
                    qualifiers: scope.qualifiers,
                    initFunction: scope.initFunction,
                    preSearch: scope.preSearch,
                    editUriState: scope.editUriState,
                    canAddAnother: scope.canAddAnother || false,
                    previewable: scope.previewable || false,
                    dimmedColumnName: scope.dimmedColumnName
                }).then(function(data) {
                    executeAction({
                        type: 'modal.select',
                        value: data
                    });
                }).catch(function() {
                    executeAction({
                        type: 'modal.cancel'
                    });
                });
            }

            function markSelected(items) {
                var k1, k2;
                if (ngModelCtrl.$viewValue == null || items == null) {
                    return;
                }

                _.each(items, function(item) {
                    k1 = getKeyValue(item);
                    var contains = _.any(ngModelCtrl.$viewValue, function(item2) {
                        k2 = getKeyValue(item2);
                        return k1 === k2;
                    });

                    if (contains) {
                        item.$selected = true;
                    }
                });
            }

            function setLoading(isLoading) {
                scope.loading = ngModelCtrl.$loading = Boolean(isLoading);

                if (formCtrl) {
                    formCtrl.$update();
                }
            }

            function adjustMultiSelectInputWidth() {
                var minWidth = 50;
                var input = element.find('input.typeahead');
                input.width(minWidth);
                setTimeout(function() {
                    var container = element.find('.tags');
                    var lastTag = element.find('.label-tag:last');
                    if (lastTag.length) {
                        var width = container.width() - (lastTag.offset().left - container.offset().left + lastTag.innerWidth());
                        input.width(width < minWidth ? '100%' : width);
                    } else {
                        input.width('100%');
                    }
                }, 10);
            }
        }
    };
});