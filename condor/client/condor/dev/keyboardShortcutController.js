(function() {
    'use strict';

    angular.module('inprotech.dev')
        .run(function(modalService) {
            modalService.register('devcheatsheet', 'CheatSheetController', 'condor/dev/shortcutcheatsheettemplate.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: true,
                size: 'lg'
            });
        });

    angular.module('inprotech.dev')
        .controller('CheatSheetController', ['$scope', 'hotkeys', '$uibModalInstance',
            function($scope, hotkeys, $uibModalInstance) {
                $scope.hotkeysList = hotkeys.get(0);

                $scope.close = function() {
                    $uibModalInstance.close();
                };
            }
        ]);

    angular.module('inprotech.dev')
        .controller('KeyboardShortcutController', ['hotkeys', 'notificationService', '$scope', 'modalService',
            function(hotkeys, notificationService, $scope, modalService) {

                $scope.listOfShortcuts = [];

                hotkeys.add({
                    combo: '?',
                    description: 'Display shortcuts',
                    callback: function() {
                        $scope.displayCheatSheet();
                    }
                }).type = 'main';


                $scope.addShortcut = function() {
                    if (!$scope.shortcut) {
                        return;
                    }
                    var combo = $scope.shortcut.toLowerCase();
                    $scope.listOfShortcuts.push(combo);

                    var key = hotkeys.add({
                        combo: combo,
                        description: 'Shortcut: ' + combo,
                        callback: function() {
                            $.cpaFlashAlert(combo + ' works here!');
                        }
                    });

                    if (key) {
                        key.type = 'context';
                    }
                };

                $scope.displayCheatSheet = function() {
                    modalService.open('devcheatsheet', $scope, {});
                };
            }
        ]);
})();