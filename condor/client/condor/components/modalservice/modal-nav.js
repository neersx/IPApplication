angular.module('inprotech.components.modal').component('ipModalNav', {
    templateUrl: 'condor/components/modalservice/modal-nav.html',
    restrict: 'E',
    bindings: {
        allItems: '<',
        currentItem: '<',
        hasUnsavedChanges: '<',
        onNavigate: '<',
        hasPagination: '<?'
    },
    controllerAs: 'vm',
    controller: function (notificationService, hotkeys) {
        'use strict';

        var vm = this;
        var index;
        var prevItem;
        var nextItem;

        vm.$onInit = onInit;

        function onInit() {
            if (vm.hasPagination)
                index = _.indexOf(_.pluck(vm.allItems, 'id'), vm.currentItem.id);
            else
                index = _.indexOf(vm.allItems, vm.currentItem);
            prevItem = vm.allItems[index - 1];
            nextItem = vm.allItems[index + 1];

            _.extend(vm, {
                isFirstDisabled: !prevItem,
                isPrevDisabled: !prevItem,
                isNextDisabled: !nextItem,
                isLastDisabled: !nextItem,
                totalCount: vm.allItems.length,
                currentIndex: index + 1,
                first: first,
                prev: prev,
                next: next,
                last: last
            });

            initShortcuts();
        }

        function initShortcuts() {
            hotkeys.add({
                combo: 'alt+shift+up',
                description: 'shortcuts.page.first',
                callback: first
            });

            hotkeys.add({
                combo: 'alt+shift+left',
                description: 'shortcuts.page.prev',
                callback: prev
            });

            hotkeys.add({
                combo: 'alt+shift+right',
                description: 'shortcuts.page.next',
                callback: next
            });

            hotkeys.add({
                combo: 'alt+shift+down',
                description: 'shortcuts.page.last',
                callback: last
            });
        }

        function first() {
            navigate(vm.allItems[0]);
        }

        function prev() {
            if (prevItem) {
                navigate(prevItem);
            }
        }

        function next() {
            if (nextItem) {
                navigate(nextItem);
            }
        }

        function last() {
            navigate(vm.allItems[vm.allItems.length - 1]);
        }

        function navigate(newItem) {
            if (_.isFunction(vm.hasUnsavedChanges) && vm.hasUnsavedChanges() ||
                !_.isFunction(vm.hasUnsavedChanges) && vm.hasUnsavedChanges) {
                return notificationService.discard().then(function () {
                    vm.onNavigate(newItem);
                });
            }

            vm.onNavigate(newItem);
        }
    }
});
