angular.module('inprotech.configuration.general.jurisdictions')
    .controller('JurisdictionMaintenanceController', function (viewData, jurisdictionsService, jurisdictionMaintenanceService, notificationService, $state, bus, $translate, store, LastSearch) {
        'use strict';

        var vm = this;
        var topics;
        vm.$onInit = onInit;

        function onInit() {
            vm.context = 'jurisdictions.detail';
            vm.viewData = viewData;
            vm.lastSearch = jurisdictionsService.lastSearch;
            vm.canEdit = viewData.canEdit;
            vm.save = save;
            vm.delete = deleteJurisdiction;
            vm.discard = discard;
            vm.isSaveEnabled = isSaveEnabled;
            vm.isDiscardEnabled = isDiscardEnabled;
            vm.onTopicSelected = onTopicSelected;
            vm.isNavigated = false;
            vm.defaultJurisdiction = setState();
            vm.setInUse = setInUse;

            setLastSearchIfEmpty();
            initializeTopics();
        }

        function setLastSearchIfEmpty() {
            var args = store.local.get('lastSearch');
            if (!vm.lastSearch && args) {
                vm.lastSearch = new LastSearch({
                    method: jurisdictionsService.search,
                    methodName: 'search',
                    args: [args[0], args[1]]
                });
            }
        }

        function setState() {
            if ($state.params && $state.params.navigatedSource === 'jurisdictionpicklist') {
                vm.isNavigated = true;
                return true;
            }
            return $state.params.navigatedSource && $state.params.navigatedSource === 'classes' ? true : false;
        }

        function initializeTopics() {
            topics = {
                overview: {
                    key: 'overview',
                    title: 'jurisdictions.maintenance.sections.overview',
                    template: '<ip-jurisdiction-overview view-data="$topic.viewData" data-topic="$topic">',
                    viewData: vm.viewData
                },
                groups: {
                    key: 'groups',
                    title: 'jurisdictions.maintenance.sections.groups',
                    template: '<ip-jurisdiction-groups parent-id="$topic.parentId" type="$topic.type" data-topic="$topic">',
                    parentId: vm.viewData.id,
                    jurisdiction: vm.viewData.name,
                    type: vm.viewData.type,
                    canUpdate: vm.canEdit && vm.viewData.type !== '2',
                    allMembersFlag: vm.viewData.allMembersFlag
                },
                attributes: {
                    key: 'attributes',
                    title: 'jurisdictions.maintenance.sections.attributes',
                    template: '<ip-jurisdiction-attributes parent-id="$topic.parentId" data-topic="$topic">',
                    parentId: vm.viewData.id,
                    canUpdate: vm.canEdit,
                    type: vm.viewData.type,
                    reportPriorArt: vm.viewData.reportPriorArt
                },
                texts: {
                    key: 'texts',
                    title: 'jurisdictions.maintenance.sections.texts',
                    template: '<ip-jurisdiction-texts parent-id="$topic.parentId" data-topic="$topic">',
                    parentId: vm.viewData.id,
                    canUpdate: vm.canEdit
                }
            };

            vm.options = {
                topics: [topics.overview, topics.groups, topics.attributes, topics.texts],
                actions: []
            };

            if (vm.viewData.type === '1') {
                vm.options.topics.push({
                    key: 'statusflags',
                    title: 'jurisdictions.maintenance.sections.designationStages',
                    template: '<ip-jurisdiction-status-flags parent-id="$topic.parentId" data-topic="$topic">',
                    canUpdate: vm.canEdit,
                    parentId: vm.viewData.id
                });
            }

            vm.options.topics.push({
                key: 'classes',
                title: 'jurisdictions.maintenance.sections.classes',
                template: '<ip-jurisdiction-classes parent-id="$topic.parentId" data-topic="$topic">',
                parentId: vm.viewData.id,
                jurisdiction: vm.viewData.name,
                canUpdate: vm.canEdit,
                activeTopic: $state.params.navigatedSource
            });

            if (vm.viewData.type === '0') {
                vm.options.topics.push({
                    key: 'states',
                    title: 'jurisdictions.maintenance.sections.states',
                    template: '<ip-jurisdiction-states parent-id="$topic.parentId" state-label="$topic.stateLabel" data-topic="$topic">',
                    parentId: vm.viewData.id,
                    canUpdate: vm.canEdit,
                    stateLabel: vm.viewData.stateLabel
                });
            }

            vm.options.topics.push({
                key: 'businessDays',
                title: 'jurisdictions.maintenance.sections.businessDays',
                template: '<ip-jurisdiction-business-days parent-id="$topic.parentId" work-day-flag="$topic.workDayFlag" data-topic="$topic">',
                parentId: vm.viewData.id,
                workDayFlag: vm.viewData.workDayFlag,
                canUpdate: vm.canEdit
            });

            if (vm.viewData.type === '0') {
                vm.options.topics.push({
                    key: 'addressSettings',
                    title: 'jurisdictions.maintenance.sections.addressSettings',
                    template: '<ip-jurisdiction-address-settings view-Data="$topic.viewData" data-topic="$topic">',
                    viewData: vm.viewData,
                    canUpdate: vm.canEdit
                });
            }

            vm.options.topics = vm.options.topics.concat([{
                key: 'defaults',
                title: 'jurisdictions.maintenance.sections.billingdefaults',
                template: '<ip-jurisdiction-defaults view-Data="$topic.viewData" data-topic="$topic">',
                viewData: vm.viewData,
                canUpdate: vm.canEdit
            }, {
                key: 'validNumbers',
                title: 'jurisdictions.maintenance.sections.numberPatterns',
                template: '<ip-jurisdiction-valid-numbers parent-id="$topic.parentId" data-topic="$topic">',
                parentId: vm.viewData.id,
                jurisdiction: vm.viewData.name,
                canUpdate: vm.canEdit
            }, {
                key: 'validCombinations',
                title: 'jurisdictions.maintenance.sections.validCombinations',
                template: '<ip-jurisdiction-valid-combinations parent-id="$topic.parentId" parent-name="$topic.parentName" data-topic="$topic">',
                parentId: vm.viewData.id,
                parentName: vm.viewData.name
            }]);
        }

        function flatten(topics, output) {
            _.each(topics, function (topic) {
                output.push(topic);
                if (topic.topics) {
                    flatten(topic.topics, output);
                }
            });
        }

        function onTopicSelected(topicKey) {
            var flattenTopics = [];
            flatten(maintainableTopics(), flattenTopics);
            _.each(flattenTopics, function (topic) {
                if (topic.key === topicKey) {
                    if (_.isFunction(topic.initializeShortcuts)) {
                        topic.initializeShortcuts();
                    }
                }
            });
        }

        function save() {
            var isInvalid;
            var errorTopics = [];
            _.each(maintainableTopics(), function (t) {
                if (_.isFunction(t.validate) && !t.validate()) {
                    errorTopics.push({
                        message: t.title
                    });
                    isInvalid = true;
                }
            });

            if (isInvalid) {
                showSaveError(errorTopics);
                return;
            }
            var topicsData = getData();
            return jurisdictionMaintenanceService.save(viewData.id, topicsData).then(function (result) {
                jurisdictionMaintenanceService.saveResponse = null;
                if (result.data.result == 'success') {
                    if (result.data.hasInUseItems) {
                        setInUse(result.data.saveResponse);
                        notificationService.alert({
                            title: 'modal.unableToComplete',
                            message: 'modal.alert.alreadyInUse'
                        }).then(function () { }, function () {
                            jurisdictionMaintenanceService.saveResponse = result.data.saveResponse;
                            reload();
                        });

                    } else {
                        reload();
                        notificationService.success();
                    }
                } else {
                    if (result.data.result.errors && result.data.result.errors.length) {
                        var errors = result.data.result.errors.map(function (e) {
                            var topic = getMaintainableTopic(e.topic, maintainableTopics());
                            return $translate.instant(topic.title) + ' - ' + $translate.instant(e.message);
                        });
                        showSaveError(errors);
                    }
                }
            });
        }

        function setInUse(saveResponse) {
            if (saveResponse != null) {
                _.each(vm.options.topics, function (t) {
                    if (t.setInUseError) {
                        var saveResponseForTopic = _.first(_.where(saveResponse, {
                            topicName: t.key
                        }))
                        if (saveResponseForTopic !== null) {
                            t.setInUseError(saveResponseForTopic.inUseItems);
                        }
                    }
                });
            }
        }

        function showSaveError(errors) {
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: 'sections.errors.errorInSection',
                errors: errors,
                actionMessage: 'sections.errors.actionMessage'
            });
        }

        function getData() {
            var data = {};

            _.each(maintainableTopics(), function (t) {
                data = angular.extend(data, t.getFormData());
            });

            return data;
        }

        function deleteJurisdiction() {
            notificationService.confirmDelete({
                message: 'modal.confirmDelete.message'
            }).then(function () {
                jurisdictionMaintenanceService.delete([viewData.id]).then(function (response) {
                    if (response.data.result === 'success') {
                        notificationService.success();
                        navigateToNext();
                    } else {
                        notificationService.alert({
                            title: 'modal.unableToComplete',
                            message: 'modal.alert.alreadyInUseDelFromMaint'
                        });
                    }
                });
            });
        }

        function discard() {
            reload();
        }

        function reload() {
            vm.isSaveEnabled = _.constant(false);
            $state.reload($state.current.name);
        }

        function isAnyDirty() {
            return _.any(maintainableTopics(), function (t) {
                return t.isDirty();
            });
        }

        function ensureAllInitialised() {
            if (!_.all(maintainableTopics(), function (t) {
                if (t) {
                    return t.initialised;
                }
            })) {
                return false;
            }
            return true;
        }

        function isSaveEnabled() {
            if (!ensureAllInitialised()) {
                return false;
            }

            return isAnyDirty() && _.all(maintainableTopics(), function (t) {
                return !t.hasError();
            });
        }

        function isDiscardEnabled() {
            if (!ensureAllInitialised()) {
                return false;
            }

            return isAnyDirty();
        }

        function maintainableTopics() {
            var maintainableTopics = [topics.overview, topics.groups, topics.attributes, topics.texts];
            var statusFlagTopic = getMaintainableTopic('statusflags', vm.options.topics);
            if (statusFlagTopic)
                maintainableTopics.push(statusFlagTopic);
            //classes
            var classesTopic = getMaintainableTopic('classes', vm.options.topics);
            if (classesTopic)
                maintainableTopics.push(classesTopic);
            //defaults defaults
            var billingDefaultsTopic = getMaintainableTopic('defaults', vm.options.topics);
            if (billingDefaultsTopic)
                maintainableTopics.push(billingDefaultsTopic);

            //states
            var statesTopic = getMaintainableTopic('states', vm.options.topics);
            if (statesTopic)
                maintainableTopics.push(statesTopic);
            // addressSettings
            var addressSettingsTopic = getMaintainableTopic('addressSettings', vm.options.topics);
            if (addressSettingsTopic)
                maintainableTopics.push(addressSettingsTopic);
            //validNumbers
            var validNumbersTopic = getMaintainableTopic('validNumbers', vm.options.topics);
            if (validNumbersTopic)
                maintainableTopics.push(validNumbersTopic);
            // businessDays
            var businessDaysTopic = getMaintainableTopic('businessDays', vm.options.topics);
            if (businessDaysTopic)
                maintainableTopics.push(businessDaysTopic);
            return maintainableTopics;
        }

        function getMaintainableTopic(key, topics) {
            return _.first(_.filter(topics, function (topic) {
                return topic.key === key;
            }));
        }

        function navigateToNext() {
            vm.isSaveEnabled = _.constant(false);
            var ids = vm.lastSearch.ids;
            var index = _.indexOf(ids, viewData.id);
            var total = ids ? ids.length : 0;
            var stateParam = {
                id: viewData.id
            }

            bus.channel('gridRefresh.searchResults').broadcast();

            if (total <= 1) {
                $state.go('^', null, {
                    location: 'replace'
                });
                return;
            } else if (index < total - 1) {
                stateParam.id = ids[index + 1];
            } else if (index === total - 1) {
                stateParam.id = ids[index - 1];
            }

            ids.splice(index, 1);
            $state.go('jurisdictions.detail', stateParam, {
                location: 'replace'
            });
        }
    });