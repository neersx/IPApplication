angular.module('inprotech.processing.policing')
    .controller('PolicingNextRunTimeController', function($scope, modalService, notificationService, hotkeys) {

        var minutesGap = 5;
        $scope.selectedHour = $scope.selectedMinutes = '00';

        $scope.knownHours = [];

        $scope.knownMinutes = [];

        if ($scope.currentDate) {
            var display = moment.utc($scope.currentDate);

            $scope.selectedDate = display.toDate();

            display = display.add((minutesGap - display.minutes()) % minutesGap, 'minutes');

            $scope.selectedHour = display.format('HH');

            $scope.selectedMinutes = display.format('mm');
        }

        $scope.dismissAll = function() {
            if ($scope.isSaveDisabled()) {
                modalService.close('NextRunTime');
                return;
            }
            notificationService.discard()
                .then(function() {
                    modalService.close('NextRunTime');
                });
        };

        $scope.isSaveDisabled = function() {
            return $scope.isEmpty() || !$scope.nextrunform.$dirty;
        };

        $scope.save = function() {
            $scope.$emit('nextRunTime', getSelectedDateTime());
            modalService.close('NextRunTime');
        };

        $scope.isEmpty = function() {
            return !($scope.selectedDate && $scope.selectedHour && $scope.selectedMinutes);
        }

        $scope.initShortcut = function() {
            hotkeys.add({
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: function() {
                    if (!$scope.isSaveDisabled()) {
                        $scope.save();
                    }
                }
            });
            hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: function() {
                    $scope.dismissAll();
                }
            });
        }

        function getSelectedDateTime() {
            return $scope.selectedDate.getFullYear() + '-' + ($scope.selectedDate.getMonth() + 1) + '-' + $scope.selectedDate.getDate() + 'T' + $scope.selectedHour + ':' + $scope.selectedMinutes;
        }
    });
