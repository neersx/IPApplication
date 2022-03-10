angular.module('inprotech.components.page').component('ipDetailPageNav', {
    templateUrl: 'condor/components/page/detail-page-nav.html',
    bindings: {
        routerState: '@',
        paramKey: '@',
        lastSearch: '<?',
        ids: '<?',
        totalRows: '<?',
        fetchNext: '&?'
    },
    controllerAs: 'vm',
    controller: function ($stateParams, $state, hotkeys, $scope) {
        'use strict';
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.paramKey = vm.paramKey || 'id';
            vm.visible = false;
            vm.rowsPerRequest = 200;

            if (vm.ids) {
                processIds(vm.ids);
            } else if (vm.lastSearch) {
                vm.lastSearch.getAllIds().then(processIds);
            }

            initShortcuts();
        }

        vm.navigate = function (id) {
            var index = findIndex(id, vm.ids);
            var routerParams = {};
            routerParams[vm.paramKey] = (id !== null && id.key != null) ? id.key : id;

            if (index === -1) {
                if (!vm.canFetchNext) return;

                vm.fetchNext({
                    currentIndex: (+id === +vm.total) ? (vm.total - vm.rowsPerRequest) : id
                })
                    .then(function (ids) {
                        vm.ids = ids;
                        $state.go(vm.routerState, routerParams);
                        return;
                    });
            } else {
                $state.go(vm.routerState, routerParams);
            }
        };        

        function processIds(ids) {
            var index = findIndex($stateParams[vm.paramKey], ids);
            if (index === -1)
                return;

            var isObject = ids[0].key != null;
            if (!vm.ids) {
                vm.ids = ids;
            }

            vm.current = (isObject) ? +$stateParams[vm.paramKey] : index + 1;
            vm.total = vm.totalRows || ids.length;
            vm.prevId = vm.current === 1 ? null : (isObject) ? (vm.current - 1).toString() : ids[index - 1];
            vm.nextId = vm.current === vm.total ? null : (isObject) ? (vm.current + 1).toString() : ids[index + 1];
            vm.canFetchNext = vm.current < vm.total && ids.length < vm.total;
            vm.available = ids.length;
            vm.firstId = (isObject) ? '1' : ids[0];
            vm.lastId = (isObject) ? vm.total.toString() : ids[ids.length - 1];
            vm.visible = true;

            $scope.$emit('detailNavigate', {
                currentPage: (isObject) ? (vm.current - 1) : index
            });
        }

        function findIndex(id, ids) {
            var index = -1;
            if (ids && ids.length > 0 && id != null) {
                if (ids[0].key != null) {
                    index = _.findIndex(ids, {
                        key: id
                    });
                } else {
                    var int_id = parseInt(id);
                    if (isNaN(int_id)) {
                        int_id = id;
                    }
                    index = _.indexOf(ids, int_id);
                }
            }
            return index;
        }

        function initShortcuts() {
            hotkeys.add({
                combo: 'alt+shift+up',
                description: 'shortcuts.page.first',
                callback: function () {
                    vm.navigate(vm.firstId);
                }
            });

            hotkeys.add({
                combo: 'alt+shift+left',
                description: 'shortcuts.page.prev',
                callback: function () {
                    vm.navigate(vm.prevId);
                }
            });

            hotkeys.add({
                combo: 'alt+shift+right',
                description: 'shortcuts.page.next',
                callback: function () {
                    vm.navigate(vm.nextId);
                }
            });

            hotkeys.add({
                combo: 'alt+shift+down',
                description: 'shortcuts.page.last',
                callback: function () {
                    vm.navigate(vm.lastId);
                }
            });
        }
    }
});