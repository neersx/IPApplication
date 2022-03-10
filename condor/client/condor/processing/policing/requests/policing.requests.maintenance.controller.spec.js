describe('inprotech.processing.policing.PolicingRequestMaintenanceController', function() {
    'use strict';
    var c, modalService, service, scope, controller, modelInstance, request, promiseMock, notificationService, charsService, extObjFactory, affectedCasesService, canCalculateAffectedCases, requestReminderHelper;
    beforeEach(function() {
        module('inprotech.processing.policing');
        module('inprotech.configuration.general.validcombination');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing', 'inprotech.mocks.core', 'inprotech.mocks.components.notification', 'inprotech.core.extensible']);
            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            service = $injector.get('PolicingRequestServiceMock');
            $provide.value('policingRequestService', service);

            modelInstance = $injector.get('ModalInstanceMock');
            $provide.value('$uibModalInstance', modelInstance);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            promiseMock = $injector.get('promiseMock');

            $provide.value('request', request);

            charsService = $injector.get('policingCharacteristicsServiceMock');
            $provide.value('policingCharacteristicsService', charsService);

            affectedCasesService = $injector.get('policingRequestAffectedCasesServiceMock');
            $provide.value('policingRequestAffectedCasesService', affectedCasesService);

            requestReminderHelper = $injector.get('requestReminderHelperMock');
            $provide.value('requestReminderHelper', requestReminderHelper);

            requestReminderHelper.areDatesEqual.and.returnValue(false);
            requestReminderHelper.positiveOrEmptyDays.and.returnValue(true);
            requestReminderHelper.convertForDatePicker.and.returnValue('123')

            extObjFactory = $injector.get('ExtObjFactory');

        });
    });

    beforeEach(inject(function($controller, $rootScope) {

        scope = $rootScope.$new();
        canCalculateAffectedCases = true;
        affectedCasesService.getAffectedCases = promiseMock.createSpy({
            data: {
                isSupported: true,
                noOfCases: 1
            }
        });
        spyOn(scope, '$apply').and.callFake(function(cb) {
            return cb();
        });
        controller = function(request) {
            c = $controller('PolicingRequestMaintenanceController', {
                $scope: scope,
                request: request,
                ExtObjFactory: extObjFactory,
                canCalculateAffectedCases: canCalculateAffectedCases
            });
            c.$onInit();
            c.form = {
                case: { $setTouched: jasmine.createSpy(), $setValidity: jasmine.createSpy() }
            };
            c.optionsForm = {};
            c.startDate = null;
            c.endDate = null;
            c.dateLetters = null;
            return c;
        };
        charsService.characteristicFields = [];
    }));

    describe('Edit mode', function() {
        var _timeout;
        beforeEach(inject(function($timeout) {
            _timeout = $timeout;
            request = {
                requestId: 1,
                title: 'Request to edit',
                options: {},
                attributes: {
                    caseReference: {
                        key: 0,
                        code: '1234/A',
                        value: 'NOTFOUND'
                    }
                }
            };
            controller(request);
        }));

        it('should initialze data from the passed request details', function() {
            expect(c.request.title).toBe('Request to edit');
        });

        it('should set error on case reference, if case reference not found', function() {
            _timeout.flush(500);
            expect(c.form.case.$setTouched).toHaveBeenCalled();
            expect(c.form.case.$setValidity).toHaveBeenCalledWith('caseDoesNotExists', false);
        });
    });

    describe('Add mode', function() {
        describe('initialise', function() {
            it('should initialise request object', function() {
                controller();

                expect(c.request).toBeDefined();
                expect(c.options.reminders).toBeTruthy();
                expect(c.options.emailReminders).toBeTruthy();
                expect(c.options.documents).toBeTruthy();
            });
        });

        describe('reminder date enable and disable', function() {
            it('should disable date when reminders and adhoc reminders are disabled', function() {
                controller();

                c.options.reminders = false;

                expect(c.disableReminders()).toBeTruthy();
            });

            it('should not disable date when reminders or adhoc reminders are enabled', function() {
                controller();

                expect(c.disableReminders()).toBeFalsy();

                c.options.reminders = false;
                c.options.adhocReminders = true;

                expect(c.disableReminders()).toBeFalsy();
            });

            it('should disable date when recalculate reminders is selected', function() {
                controller();

                c.options.recalculateReminderDates = true;

                expect(c.disableReminders()).toBeTruthy();
            });
        });

        describe('should reset', function() {
            it('date when reminders are disabled', function() {
                controller();
                c.request.startDate = new Date('01-Jan-2016');
                c.options.recalculateReminderDates = true;

                expect(c.disableReminders()).toBeTruthy();
                expect(c.request.startDate).toBeNull();
            });

            it('adhocReminders on recalculate of reminderDate', function() {
                controller();

                c.options.adhocReminders = true;
                c.onChangeReCalc.reminderDate();

                expect(c.options.adhocReminders).toBeFalsy();
            });

            it('options on recalculate of dueDate', function() {
                controller();

                c.options.adhocReminders = true;
                c.options.recalculateReminderDates = false;
                c.options.recalculateEventDates = true;

                c.onChangeReCalc.dueDate();

                expect(c.options.adhocReminders).toBeFalsy();
                expect(c.options.recalculateReminderDates).toBeTruthy();
                expect(c.options.recalculateEventDates).toBeFalsy();
            });

            it('options on recalculate of criteria', function() {
                controller();

                c.options.adhocReminders = true;
                c.options.recalculateDueDates = false;
                c.options.recalculateReminderDates = false;

                c.onChangeReCalc.criteria();

                expect(c.options.adhocReminders).toBeFalsy();
                expect(c.options.recalculateDueDates).toBeTruthy();
                expect(c.options.recalculateReminderDates).toBeTruthy();
            });
        });
    });

    describe('Save', function() {

        function init() {
            controller();
            c.request.getRaw = promiseMock.createSpy({});
            c.options.getRaw = promiseMock.createSpy({});
            c.formData.getRaw = promiseMock.createSpy({});
            c.request.title = 'abc';
            c.requestMaintainForm = {
                $setPristine: jasmine.createSpy(),
                $valid: true
            };
            c.form = {
                $valid: true
            };
            c.optionsForm = {
                $valid: true
            };

            service.save = promiseMock.createSpy({
                data: {
                    status: 'success',
                    requestId: 1
                }
            });
        }

        beforeEach(function() {
            init();
        });

        it('should call service to save data', function() {
            c.save();

            expect(service.save).toHaveBeenCalled();
            expect(affectedCasesService.getAffectedCases).toHaveBeenCalledWith(1);
        });

        it('should not calculate affected cases if feature not available', function() {
            canCalculateAffectedCases = false;
            init();
            c.save();

            expect(service.save).toHaveBeenCalled();
            expect(affectedCasesService.getAffectedCases).not.toHaveBeenCalled();
        });

        it('should not close the dialog after successful save', function() {
            c.save();

            expect(notificationService.success).toHaveBeenCalled();
            expect(modelInstance.close).not.toHaveBeenCalled();
        });


        it('should display error message and keep the dialog displayed in case of error', function() {
            service.save = promiseMock.createSpy({
                data: {
                    status: 'error',
                    error: 'duplicateTitle'
                }
            });

            c.save();
            expect(modelInstance.close).not.toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalled();
        });
    });
    describe('Selecting a case', function() {
        var selectedCase;
        beforeEach(function() {
            selectedCase = {
                key: 'key'
            };
        });

        it('Resets all characteristics fields except action and event', function() {
            var c = controller();
            c.formData.case = selectedCase;

            var resetSpyFn = jasmine.createSpy('resetSpy');
            charsService.characteristicFields = ['a', 'b', 'action', 'event'];
            charsService.isCharacteristicField = jasmine.createSpy();
            _.each(charsService.characteristicFields, function(field) {
                c.form[field] = {
                    $reset: resetSpyFn
                };
            });

            var notCalledSpyFn = jasmine.createSpy('notCalledSpy');
            c.form.nonCharacteristicField = {
                $reset: notCalledSpyFn
            };

            c.selectCase();

            expect(resetSpyFn.calls.count()).toBe(charsService.characteristicFields.length - 2);
            expect(notCalledSpyFn).not.toHaveBeenCalled();
        });
    });

    describe('Affected Cases', function() {
        function init() {
            request = {
                requestId: 1,
                title: 'Request to edit',
                options: {},
                attributes: {}
            };
            controller(request);
            c.request.getRaw = promiseMock.createSpy({});
            c.options.getRaw = promiseMock.createSpy({});
            c.formData.getRaw = promiseMock.createSpy({});
            c.requestMaintainForm = {
                $setPristine: jasmine.createSpy(),
                $valid: true
            };
            c.form = {
                $valid: true
            };
            c.optionsForm = {
                $valid: true
            };
        }

        it('should get affected cases', function() {
            init();
            expect(c.currentAffectedCases.state).toEqual(2);
            expect(c.currentAffectedCases.cases).toEqual(1);
            service.save = promiseMock.createSpy({
                data: {
                    status: 'success',
                    requestId: 1
                }
            });
            affectedCasesService.getAffectedCases = promiseMock.createSpy({
                data: {
                    isSupported: true,
                    noOfCases: 3
                }
            });

            c.save();

            expect(affectedCasesService.getAffectedCases).toHaveBeenCalledWith(c.request.requestId);
            expect(c.currentAffectedCases.state).toEqual(2);
            expect(c.currentAffectedCases.cases).toEqual(3);

        });

        it('should not get affected cases if feature unavailable', function() {
            canCalculateAffectedCases = false;
            init();
            expect(c.currentAffectedCases.state).toEqual(0);
            expect(c.currentAffectedCases.cases).toEqual(null);
            service.save = promiseMock.createSpy({
                data: {
                    status: 'success',
                    requestId: 1
                }
            });
            c.save();
            expect(affectedCasesService.getAffectedCases).not.toHaveBeenCalled();
            expect(c.currentAffectedCases.state).toEqual(0);
            expect(c.currentAffectedCases.cases).toEqual(null);
        });
    });

    describe('Date Manipulation', function() {
        beforeEach(function() {
            request = {
                requestId: 1,
                title: 'Request to edit',
                options: {},
                attributes: {}
            };
            controller(request);
            modalService.open = promiseMock.createSpy('Success');
            c.optionsForm = {
                startDate: {
                    $setValidity: promiseMock.createSpy()
                },
                endDate: {
                    $setValidity: promiseMock.createSpy()
                }
            };
        });

        describe('change of day', function() {
            it('should Fetch Next Letters Date when date changes', function() {
                var dt = new Date();
                c.request.startDate = dt;
                service.getNextLettersDate = promiseMock.createSpy({
                    data: dt
                });

                requestReminderHelper.areDatesEqual.and.returnValue(false);
                requestReminderHelper.positiveOrEmptyDays.and.returnValue(true);
                requestReminderHelper.convertForDatePicker.and.returnValue('123')

                c.onDateBlur('startDate', dt);
                expect(service.getNextLettersDate).toHaveBeenCalled();
                expect(c.request.dateLetters).toEqual('123');
            });

            it('should Fetch Next Letters Date when date changes', function() {
                var dt = new Date();
                c.request.startDate = dt;
                service.getNextLettersDate = promiseMock.createSpy({
                    data: dt
                });

                c.onDateBlur('startDate', dt);
                expect(service.getNextLettersDate).toHaveBeenCalled();
                expect(c.request.dateLetters).toEqual('123');
            });

            it('should set end date when start date is provided', function() {
                var dt = new Date('2016-09-20');
                c.request.startDate = dt;
                c.request.forDays = 5;
                requestReminderHelper.addDays.and.returnValue('2016-09-24');

                c.onChangeforDay();
                expect(c.request.endDate).toEqual('2016-09-24');
            });

            it('should set start date when end date is provided', function() {
                var dt = new Date('2016-09-20');
                c.request.endDate = dt;
                c.request.forDays = 5;
                c.request.startDate = null;
                requestReminderHelper.addDays.and.returnValue('2016-09-16');

                c.onChangeforDay();
                expect(c.request.startDate).toEqual('2016-09-16');
            });

            it('should not set dates if dates are null', function() {
                c.request.forDays = 5;
                c.request.endDate = null;
                c.request.startDate = null;

                c.onChangeforDay();
                expect(c.request.startDate).not.toBeUndefined();
                expect(c.request.endDate).not.toBeUndefined();
            });

            it('should not change dates if days are negative', function() {
                var dt = new Date('2016-09-20');
                c.request.startDate = dt;
                c.request.endDate = dt;
                c.request.forDays = -5;

                c.onChangeforDay();
                expect(c.request.startDate).toEqual(dt);
                expect(c.request.endDate).toEqual(dt);
            });
        });

        describe('Start and End Date change', function() {
            it('should set days when start date is changed', function() {
                var dt = new Date('2016-09-20');
                var endDateDt = new Date('2016-09-21');
                c.request.endDate = endDateDt;
                service.getNextLettersDate = promiseMock.createSpy({
                    data: dt
                });

                c.onDateBlur('startDate', dt);
                expect(requestReminderHelper.setForDays).toHaveBeenCalledWith(dt, endDateDt);
            });

            it('should set days when end date is changed', function() {
                c.request.startDate = new Date('2016-09-20');
                var newDate = new Date('2016-09-25');
                requestReminderHelper.setForDays.and.returnValue(6);

                c.onDateBlur('endDate', newDate);
                expect(requestReminderHelper.setForDays).toHaveBeenCalledWith(c.request.startDate, newDate);
            });
        });

    });

    describe('Run now modal', function() {
        beforeEach(function() {
            request = {
                requestId: 1,
                title: 'Request to edit',
                options: {},
                attributes: {}
            };
            controller(request);
            c.request.getRaw = promiseMock.createSpy({});
            c.options.getRaw = promiseMock.createSpy({});
            c.formData.getRaw = promiseMock.createSpy({});
            c.requestMaintainForm = {
                $setPristine: jasmine.createSpy()
            };
        });

        it('should not open run modal if in add mode and request is not saved', function() {
            c.request.requestId = null;
            c.runRequest();
            expect(notificationService.info).toHaveBeenCalled();
        });

        it('should not open run modal if state is dirty', function() {
            c.request.title = 'Unsaved value';
            c.runRequest();
            expect(notificationService.info).toHaveBeenCalled();
        });

        describe('set affected cases values using run now modal', function() {
            beforeEach(function() {
                setRunNowCallback(5);
                service.runNow = promiseMock.createSpy();
                affectedCasesService.getAffectedCases.calls.reset();
            });

            function setRunNowCallback(noOfAffectedCases) {
                modalService.open.and.callFake(function(id, scope, resolve) {
                    scope.id = id;
                    resolve.request.noOfAffectedCases = noOfAffectedCases;
                    return {
                        then: function(cb) {
                            return cb({
                                runType: 1
                            });
                        }
                    };
                });
            }

            it('should apply value from run now Modal if current value is null', function() {
                c.currentAffectedCases.cases = null;
                c.runRequest();
                expect(modalService.open).toHaveBeenCalled();
                expect(c.currentAffectedCases.cases).toBe(5);
                expect(affectedCasesService.getAffectedCases).not.toHaveBeenCalled();
            });

            it('should Not apply value from run now Modal if current value is Not null', function() {
                c.currentAffectedCases.cases = 1;
                c.runRequest();
                expect(modalService.open).toHaveBeenCalled();
                expect(c.currentAffectedCases.cases).toBe(1);
                expect(affectedCasesService.getAffectedCases).not.toHaveBeenCalled();
            });

            it('should call service to get affected cases if both current and modal values are null', function() {
                c.currentAffectedCases.cases = null;
                setRunNowCallback(null);
                c.runRequest();
                expect(modalService.open).toHaveBeenCalled();
                expect(affectedCasesService.getAffectedCases).toHaveBeenCalledWith(c.request.requestId);
            });
        });
    });
});