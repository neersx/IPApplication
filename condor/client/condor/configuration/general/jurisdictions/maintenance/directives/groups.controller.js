angular.module('inprotech.configuration.general.jurisdictions').controller('GroupsController', function ($scope, kendoGridBuilder, jurisdictionGroupsService, jurisdictionMaintenanceService, dateService, modalService, hotkeys, $translate, notificationService, focus) {
    'use strict';

    var vm = this;
    var parentId;
    vm.$onInit = onInit;

    function onInit() {
        parentId = $scope.parentId;
        vm.context = 'groups';
        vm.gridOptions = buildGridOptions();
        vm.search = search;
        vm.onAddClick = onAddClick;
        vm.onEditClick = onEditClick;
        vm.type = $scope.type;
        vm.allMembersFlag = vm.topic.allMembersFlag;
        vm.displayGroups = false;
        vm.displayName = displayName;
        vm.form = {};
        vm.topic.isDirty = isFormDirty;
        vm.topic.getFormData = getTopicFormData;
        vm.topic.hasError = angular.noop;
        vm.topic.initializeShortcuts = initShortcuts;
        vm.setFormDirty = setFormDirty;
        jurisdictionGroupsService.lastSearchedOnGroups = false;
        init();

        vm.topic.initialised = true;
    }

    function init() {
        if (vm.type === '0') {
            vm.displayGroups = true;
        }
    }

    function displayName() {
        return vm.displayGroups ? $translate.instant('jurisdictions.maintenance.groupMemberships.groupName') :
            $translate.instant('jurisdictions.maintenance.groupMemberships.memberName');
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'groupMembers',
            topicItemNumberKey: vm.topic.key,
            autoBind: true,
            pageable: false,
            selectable: true,
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, error: dataItem.error}" uib-tooltip="{{dataItem.errorMessage}}" tooltip-class="tooltip-error" data-tooltip-placement="left"',
            actions: vm.topic.canUpdate ? {
                edit: {
                    onClick: 'vm.onEditClick(dataItem)'
                },
                delete: true
            } : null,
            read: function (queryParams) {
                if (vm.gridOptions.getQueryParams() !== null)
                    queryParams = vm.gridOptions.getQueryParams();
                return jurisdictionGroupsService.search(queryParams, parentId, vm.displayGroups ? 'groups' : 'members');
            },
            columns: configureColumns()
        });
    }

    function configureColumns() {
        var columns = [{
            title: 'jurisdictions.maintenance.groupMemberships.code',
            field: 'id',
            sortable: true
        }, {
            title: 'jurisdictions.maintenance.groupMemberships.memberName',
            field: 'name',
            sortable: true,
            headerTemplate: '{{vm.displayName()}}'
        }, {
            title: 'jurisdictions.maintenance.groupMemberships.dateCommenced',
            field: 'dateCommenced',
            sortable: true,
            template: '<span>{{ dataItem.dateCommenced | localeDate }}</span>'
        }, {
            title: 'jurisdictions.maintenance.groupMemberships.dateCeased',
            field: 'dateCeased',
            sortable: true,
            template: '<span>{{ dataItem.dateCeased | localeDate }}</span>'
        }, {
            title: 'jurisdictions.maintenance.groupMemberships.fullMembershipDate',
            field: 'fullMembershipDate',
            sortable: true,
            template: '<span>{{ dataItem.fullMembershipDate | localeDate }}</span>'
        }, {
            title: 'jurisdictions.maintenance.groupMemberships.associateMember',
            field: 'isAssociateMember',
            sortable: true,
            template: '<input ng-model="dataItem.isAssociateMember" type="checkbox" disabled="true" /><span style="margin-left:10%">{{ dataItem.associateMemberDate | localeDate }}</span>'
        }, {
            title: 'jurisdictions.maintenance.groupMemberships.groupDefault',
            field: 'isGroupDefault',
            sortable: true,
            template: '<input ng-model="dataItem.isGroupDefault" type="checkbox" disabled="true" />'
        }, {
            title: 'jurisdictions.maintenance.groupMemberships.propertyTypes',
            field: 'propertyTypesName',
            sortable: false
        }];

        return columns;
    }

    function onAddClick() {
        openGroupMembershipMaintenance('add').then(function (newData) {
            addItem(newData);
        });
    }

    function onEditClick(dataItem) {
        openGroupMembershipMaintenance('edit', dataItem);
    }

    function addItem(newData) {
        vm.gridOptions.insertAfterSelectedRow(newData);
    }

    function openGroupMembershipMaintenance(mode, dataItem) {
        return modalService.openModal({
            id: 'GroupMembershipMaintenance',
            mode: mode,
            isAddAnother: false,
            controllerAs: 'vm',
            addItem: addItem,
            type: vm.type,
            parentId: parentId,
            jurisdiction: vm.topic.jurisdiction,
            allItems: vm.gridOptions.dataSource.data(),
            dataItem: dataItem,
            isGroup: vm.displayGroups
        });
    }

    function selectFilterOption(byGroup) {
        vm.displayGroups = byGroup;
        jurisdictionGroupsService.lastSearchedOnGroups = byGroup;
    }

    function search(byGroup) {
        if (isDirty()) {
            notificationService.confirm({
                title: 'Warning',
                message: 'jurisdictions.maintenance.groupMemberships.warningMessage',
                cancel: 'Cancel',
                continue: 'Proceed'
            }).then(function () {
                selectFilterOption(byGroup);
                return vm.gridOptions.search();
            }, function () {
                if (jurisdictionGroupsService.lastSearchedOnGroups !== byGroup)
                    vm.displayGroups = !byGroup;
                else
                    vm.displayGroups = byGroup;
                vm.displayGroups ? focus('display-groups') : focus('display-members');
            });
        } else {
            selectFilterOption(byGroup);
            return vm.gridOptions.search();
        }
    }

    function isDirty() {
        var data = vm.gridOptions && vm.gridOptions.dataSource && vm.gridOptions.dataSource.data();
        var dirtyGrid = data && _.any(data, function (item) {
            return item.isAdded || item.deleted || item.isEdited;
        });
        return dirtyGrid;
    }

    function isFormDirty() {
        return isDirty() || vm.form.$dirty;
    }

    function setFormDirty() {
        vm.form.$dirty = true;
    }

    function getTopicFormData() {
        return {
            groupMembershipDelta: getDelta(),
            allMembersFlag: vm.allMembersFlag
        };
    }

    function getDelta() {
        var added = getSaveModel(function (data) {
            return data.isAdded && !data.deleted;
        });

        var updated = getSaveModel(function (data) {
            return data.isEdited && !data.isAdded;
        });

        var deleted = getSaveModel(function (data) {
            return data.deleted;
        });

        return {
            added: added,
            updated: updated,
            deleted: deleted
        };
    }

    function getSaveModel(filter) {
        return _.chain(vm.gridOptions.dataSource.data())
            .filter(filter)
            .map(convertToSaveModel)
            .value();
    }

    function convertToSaveModel(dataItem) {
        var updatedRecord = {
            memberCode: vm.displayGroups ? $scope.parentId : dataItem.id,
            groupCode: vm.displayGroups ? dataItem.id : $scope.parentId,
            dateCommenced: dataItem.dateCommenced,
            dateCeased: dataItem.dateCeased,
            fullMembershipDate: dataItem.fullMembershipDate,
            associateMemberDate: dataItem.associateMemberDate,
            isGroupDefault: dataItem.isGroupDefault,
            preventNationalPhase: dataItem.preventNationalPhase,
            isAssociateMember: dataItem.isAssociateMember,
            propertyTypes: dataItem.propertyTypes
        };

        return updatedRecord;
    }

    function initShortcuts() {
        if (vm.topic.canUpdate) {
            hotkeys.add({
                combo: 'alt+shift+i',
                description: 'shortcuts.add',
                callback: onAddClick
            });
        }
    }    

});