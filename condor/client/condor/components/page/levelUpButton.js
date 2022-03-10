angular.module('inprotech.components.page').component('ipLevelUpButton', {
    template: '<a ui-sref="{{vm.toState}}(vm.stateParams)" ng-click="vm.levelUp()" class="no-underline"><span class="cpa-icon cpa-icon-arrow-circle-nw" ip-tooltip="{{::vm.tooltip}}"></span>',
    bindings: {
        toState: '@?',
        additionalStateParams: '<?',
        gridId: '@?',
        lastSearch: '<?',
        tooltip: '@'
    },
    controllerAs: 'vm',
    controller: function ($stateParams, $translate, bus, $state) {
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            var lastFootprint = _.last($state.current.footprints);

            vm.toState = vm.toState || (lastFootprint ? lastFootprint.from.name : '^');
            vm.stateParams = _.extend({}, lastFootprint ? lastFootprint.fromParams : {}, vm.additionalStateParams);

            if (!vm.tooltip) {
                $translate('LevelUp').then(function (translated) {
                    vm.tooltip = translated;
                });
            }

            if (vm.lastSearch) {
                vm.levelUp = function () {
                    // only re-page the grid if levelling up - not if levelling to a sibling level (e.g. workflow.inheritance <-> workflow.detail)
                    if (vm.toState === '^' || $state.current.name.indexOf(vm.toState) === 0) {
                        bus.channel('grid.' + vm.gridId).broadcast({
                            rowId: $stateParams.id,
                            pageIndex: vm.lastSearch.getPageForId($stateParams.id).page
                        });
                    }
                };
            }
        }
    }
});