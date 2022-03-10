angular.module('inprotech.processing.policing')
    .controller('PolicingRequestMaintenanceController', function ($scope, modalService, policingRequestService, notificationService, $translate, $uibModalInstance, request, policingCharacteristicsService, canCalculateAffectedCases, ExtObjFactory, comparer, hotkeys, requestReminderHelper, policingRequestAffectedCasesService, selectedCaseType, $timeout) {
        'use strict';

        var service = policingRequestService;
        var dateHelper = requestReminderHelper;
        var lastFetchedStartDate; //If value is directly entered in Datepicker input, then new value is directly written to model, so no indicator to get new value  

        var extObjFactory;
        var state;
        var responseBackFromModal;
        var charsService;
        var affectedCasesStates;
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {

            vm.dateLetterState = 'idle';

            charsService = policingCharacteristicsService;

            vm.selectCase = selectCase;
            vm.clearExcludeCheckbox = clearExcludeCheckbox;
            vm.canCalculateAffectedCases = canCalculateAffectedCases;
            vm.resetErrors = resetErrors;
            vm.requestFieldClasses = requestFieldClasses;
            vm.optionsFieldClasses = optionsFieldClasses;
            vm.formDataFieldClasses = formDataFieldClasses;
            extObjFactory = new ExtObjFactory().useDefaults();
            state = extObjFactory.createContext();
            responseBackFromModal = '';

            affectedCasesStates = {
                default: 0,
                loading: 1,
                ready: 2
            }

            vm.initShortcuts = initShortcuts;
            vm.currentAffectedCases = {
                state: affectedCasesStates.default,
                cases: null
            };
            vm.isCaseReferenceSelected = isCaseReferenceSelected;

            initializeRequest();
            GetAffectedCases();

            setInitErrors();
        }

        function selectCase() {
            resetCharacteristicFields();
            resetExcludeCheckBoxes();
        }

        function resetCharacteristicFields() {
            var fieldsToReset = charsService.characteristicFields.concat(['name', 'nameType']);
            _.each(fieldsToReset, function (field) {
                if (field === 'action' || field == 'event') {
                    return;
                }
                if (vm.form[field]) {
                    vm.form[field].$reset();
                }
            });
        }

        function resetExcludeCheckBoxes() {
            vm.formData.excludeProperty = false;
            vm.formData.excludeJurisdiction = false;
        }

        function clearExcludeCheckbox(fieldName, chkFieldName) {
            if (!this.formData[fieldName]) {
                this.formData[chkFieldName] = false;
            }
        }

        var initializeRequest = function () {
            if (request) {
                request.startDate = dateHelper.convertForDatePicker(request.startDate);
                request.endDate = dateHelper.convertForDatePicker(request.endDate);
                request.dateLetters = dateHelper.convertForDatePicker(request.dateLetters);
            } else {
                request = {
                    requestId: null,
                    title: '',
                    notes: '',
                    startDate: null,
                    endDate: null,
                    dateLetters: null,
                    dueDateOnly: false,
                    forDays: null,
                    options: {
                        reminders: true,
                        emailReminders: true,
                        documents: true,
                        update: false,
                        adhocReminders: false,
                        recalculateCriteria: false,
                        recalculateDueDates: false,
                        recalculateReminderDates: false,
                        recalculateEventDates: false
                    },
                    attributes: {
                        caseReference: null,
                        jurisdiction: null,
                        excludeJurisdiction: false,
                        propertyType: null,
                        excludeProperty: false,
                        caseType: null,
                        caseCategory: null,
                        subType: null,
                        office: null,
                        action: null,
                        excludeAction: false,
                        event: null,
                        dateOfLaw: null,
                        nameType: null,
                        name: null
                    }
                };
            }
            var options = request.options;
            var attributes = request.attributes;
            request.options = null;
            request.attributes = null;
            vm.request = state.attach(request);
            vm.options = state.attach(options);
            vm.formData = state.attach(attributes);
            vm.formData.$equals = picklistEquals;

            charsService.initController(vm, service.validateCharacteristics, vm.formData);
            dateHelper.init(vm.request);

            setMinEndDate();
        };

        function setInitErrors() {
            $timeout(function () {
                if (!!vm.formData && !!vm.formData.caseReference && vm.formData.caseReference.value == "NOTFOUND" && vm.formData.caseReference.key === 0 && !!vm.form && !!vm.form['case']) {
                    vm.form['case'].$setTouched();
                    vm.form['case'].$setValidity('caseDoesNotExists', false);
                }
            }, 500);
        }

        vm.dismissAll = function () {
            if (!vm.requestMaintainForm.$dirty) {
                $uibModalInstance.close(responseBackFromModal);
                return;
            }

            notificationService.discard()
                .then(function () {
                    $uibModalInstance.close();
                });
        };

        vm.save = function () {
            if (!vm.requestMaintainForm.$valid || !vm.form.$valid || !vm.optionsForm.$valid || vm.isInvalid()) {
                setTouchedForErrorFields(vm.requestMaintainForm);
                setTouchedForErrorFields(vm.form);
                setTouchedForErrorFields(vm.optionsForm);
                return;
            }
            var req = vm.request.getRaw();
            req.attributes = vm.formData.getRaw();
            req.options = vm.options.getRaw();
            service.save(req).then(afterSaveSuccess);
        };

        vm.isInvalid = function () {
            return !(vm.request && vm.request.title && vm.requestMaintainForm.$valid && vm.form.$valid && vm.optionsForm.$valid && !forDaysNotInRange());
        };

        vm.disableReminders = function () {
            var res = vm.options.recalculateReminderDates || (!vm.options.reminders && !vm.options.adhocReminders);
            if (res) {
                vm.request.startDate = null;
                vm.request.endDate = null;
                vm.request.dateLetters = null;
                vm.request.forDays = null;
                vm.request.dueDateOnly = false;
            }
            return res;
        };

        vm.onChangeReCalc = {
            criteria: function () {
                vm.options.recalculateDueDates = true;
                vm.options.recalculateReminderDates = true;
                vm.onChangeReCalc.reminderDate();
            },
            dueDate: function () {
                vm.options.recalculateReminderDates = true;
                vm.options.recalculateEventDates = false;
                vm.onChangeReCalc.reminderDate();
            },
            reminderDate: function () {
                vm.options.adhocReminders = false
            }
        };

        vm.onSelectionReminder = function () {
            vm.options.documents = false;
            vm.options.emailReminders = vm.options.reminders;
        };

        vm.caseTypeChanged = function () {
            selectedCaseType.set(vm.formData.caseType);

            if (!vm.formData.caseType) {
                vm.formData.caseCategory = '';
            }
        };

        vm.runRequest = function () {
            if (!vm.request.requestId || state.isDirty()) {
                notificationService.info({
                    title: 'policing.request.maintenance.runRequest.saveRequiredTitle',
                    message: 'policing.request.maintenance.runRequest.saveRequired'
                });
            } else {
                showRunModal();
            }
        };

        function afterSaveSuccess(response) {
            if (response.data.status == 'success') {
                if (!vm.request.requestId) {
                    vm.request.requestId = response.data.requestId;
                }
                service.savedRequestIds.push(response.data.requestId);
                saveSuccessMessage();
            } else {

                if (response.data.error.key === 'title') {
                    vm.requestMaintainForm.requestTitle.$setValidity(response.data.error.value, false);
                } else if (response.data.error.key === 'characteristics') {
                    vm.applyValidation(response.data.validationResult);
                }
                notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: $translate.instant('policing.request.maintenance.errors.' + response.data.error.key)
                });
            }
        }

        function resetErrors() {
            vm.requestMaintainForm.requestTitle.$setValidity('notunique', null);
        }

        function setTouchedForErrorFields(form) {
            _.each(form.$error, function (errorType) {
                _.each(errorType, function (errorField) {
                    errorField.$setTouched();
                })
            });
        }

        function saveSuccessMessage() {
            notificationService.success();
            state.save();
            vm.requestMaintainForm.$setPristine();
            responseBackFromModal = 'Success';
            GetAffectedCases();
        }

        function showRunModal() {
            var req = vm.request.getRaw();
            req.noOfAffectedCases = vm.currentAffectedCases.cases;
            return modalService.open('PolicingRequestRunNowConfirmation', $scope, {
                request: req,
                canCalculateAffectedCases: vm.canCalculateAffectedCases
            }, null).then(function (result) {
                updateAffectedCasesFromRunModal(req);
                if (result.runType) {
                    service.runNow(req.requestId, result.runType).then(function () {
                        notificationService.success('policing.request.runNow.success');
                    });
                }
            });
        }

        function GetAffectedCases() {
            if (vm.canCalculateAffectedCases && vm.request.requestId) {
                setAffectedState(affectedCasesStates.loading, null);

                policingRequestAffectedCasesService.getAffectedCases(vm.request.requestId).then(function (resp) {
                    if (resp.data.isSupported) {
                        $scope.$apply(function () {
                            setAffectedState(affectedCasesStates.ready, resp.data.noOfCases);
                        });
                    }
                });
            }
        }

        vm.isRequestModifiedForAffectedCases = function () {
            return !vm.request.requestId || vm.options.isDirty() || vm.formData.isDirty();
        }

        function setAffectedState(affectedCasesState, noOfAffectedCases) {
            vm.currentAffectedCases.state = affectedCasesState;
            vm.currentAffectedCases.cases = noOfAffectedCases;
        }

        function updateAffectedCasesFromRunModal(req) {
            if (!vm.canCalculateAffectedCases || vm.currentAffectedCases.cases) {
                return;
            }
            if (vm.currentAffectedCases.cases === null) {
                if (req.noOfAffectedCases !== null) {
                    setAffectedState(affectedCasesStates.ready, req.noOfAffectedCases);
                } else if (req.noOfAffectedCases === null) {
                    GetAffectedCases();
                }
            }
        }

        function requestFieldClasses(field) {
            return fieldClasses('vm.request', field);
        }

        function optionsFieldClasses(field) {
            return fieldClasses('vm.options', field);
        }

        function formDataFieldClasses(field) {
            return fieldClasses('vm.formData', field);
        }

        function fieldClasses(object, field) {
            return '{ edited: ' + object + '.isDirty(\'' + field + '\')}';
        }

        function picklistEquals(propName, newVal, oldVal) {
            if (charsService.isCharacteristicField(propName)) {
                return comparer.comparePickList(newVal, oldVal, 'key');
            }
        }

        function initShortcuts() {
            hotkeys.add({
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: function () {
                    vm.save();
                }
            });
            hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: function () {
                    vm.dismissAll();
                }
            });
        }

        function readNextLetterDate(startDate) {
            if (dateHelper.positiveOrEmptyDays()) {
                vm.dateLetterState = 'loading';
                lastFetchedStartDate = startDate;
                return service.getNextLettersDate(startDate.toISOString()).then(function (response) {
                    vm.request.dateLetters = dateHelper.convertForDatePicker(response.data);
                    vm.dateLetterState = 'idle';
                });
            }
        }

        vm.onChangeforDay = function () {
            var startDateWasValid = vm.optionsForm.startDate.$valid;
            dateHelper.setDatesValidityByDays(vm.optionsForm);

            if (vm.request.forDays > 0) {
                if (vm.request.startDate) {
                    if (!startDateWasValid && vm.optionsForm.startDate.$valid) {
                        readNextLetterDate(vm.request.startDate);
                    }
                    vm.request.endDate = dateHelper.addDays(vm.request.startDate, vm.request.forDays - 1);
                } else if (vm.request.endDate) {
                    vm.request.startDate = dateHelper.addDays(vm.request.endDate, -1 * vm.request.forDays + 1);
                }
            }
        };

        vm.onDateBlur = function (field, newVal) {
            dateHelper.setDatesValidityByDays(vm.optionsForm, field, newVal);

            if (field === 'startDate') {
                dateHelper.setForDays(newVal, vm.request.endDate);
                setMinEndDate(newVal);
                if (newVal && !dateHelper.areDatesEqual(newVal, lastFetchedStartDate)) {
                    readNextLetterDate(newVal);
                }
            } else if (field === 'endDate') {
                dateHelper.setForDays(vm.request.startDate, newVal);
            }
        };

        function setMinEndDate(startDate) {
            vm.minEndDate = startDate ? dateHelper.addDays(startDate, -1) : null;
        }

        function forDaysNotInRange() {
            return vm.request && (vm.request.forDays === 0 || vm.request.forDays > 9999 || vm.request.forDays < -9999);
        }

        function isCaseReferenceSelected() {
            return vm.formData.caseReference != null;
        }
    });