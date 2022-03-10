describe('inprotech.configuration.general.jurisdictions.GroupsController', function () {
    'use strict';

    var controller, kendoGridBuilder, service, modalService;

    beforeEach(function () {
        module('inprotech.configuration.general.jurisdictions');
        module(function ($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid', 'inprotech.mocks']);

            service = $injector.get('JurisdictionMaintenanceServiceMock');
            $provide.value('jurisdictionGroupsService', service);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
            test.mock('dateService');
            test.mock('focus', {});
            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
        });
    });

    beforeEach(inject(function ($controller) {
        controller = function (dependencies) {
            dependencies = angular.extend({
                $scope: {
                    type: '0',
                    parentId: 'AU'
                }
            }, dependencies);

            var c = $controller('GroupsController', dependencies, {
                topic: {}
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise', function () {
        it('should initialise the page, and display the correct columns', function () {
            var c = controller();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.onAddClick).toBeDefined();
            expect(c.onEditClick).toBeDefined();
            expect(c.gridOptions).toBeDefined();
            expect(c.search).toBeDefined();
            expect(c.setFormDirty).toBeDefined();
            expect(c.type).toBe('0');
            expect(c.displayGroups).toBe(true);
            expect(_.pluck(c.gridOptions.columns, 'field')).toEqual(['id', 'name', 'dateCommenced', 'dateCeased', 'fullMembershipDate', 'isAssociateMember', 'isGroupDefault', 'propertyTypesName']);
        });
    });

    describe('searching', function () {
        it('should invoke service to perform search', function () {
            var c = controller();
            c.search();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
    });

    describe('displayName', function () {
        it('should return group Name when displayGroup is true', function () {
            var c = controller();
            c.displayGroups = true;
            var name = c.displayName();
            expect(name).toBe('jurisdictions.maintenance.groupMemberships.groupName');
        });
        it('should return group Name when displayGroup is false', function () {
            var c = controller();
            c.displayGroups = false;
            var name = c.displayName();
            expect(name).toBe('jurisdictions.maintenance.groupMemberships.memberName');
        });
    });

    describe('toggle display', function () {
        it('should display member when member radio button is clicked', function () {
            var c = controller();
            c.search(false);
            expect(c.displayGroups).toBe(false);
            expect(service.lastSearchedOnGroups).toBe(false);
        });
        it('should display group when group radio button is clicked', function () {
            var c = controller();
            c.search(true);
            expect(c.displayGroups).toBe(true);
            expect(service.lastSearchedOnGroups).toBe(true);
        });
    });

    describe('add group membership', function () {
        it('should call modalService with add mode', function () {
            var c = controller();

            c.onAddClick();

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'GroupMembershipMaintenance',
                    mode: 'add'
                })));
        });
    });

    describe('edit group membership', function () {
        it('should call modalService with edit mode', function () {
            var c = controller();

            c.onEditClick();

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'GroupMembershipMaintenance',
                    mode: 'edit'
                })));
        });
    });

    describe('group membership topic', function () {
        it('should be dirty when a record is added in the grid', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isAdded: false
                        }, {
                            id: 2,
                            isAdded: true
                        }]
                    }
                }
            };
            c.form.$dirty = false;
            var isDirty = c.topic.isDirty();
            expect(isDirty).toBe(true);
        });
        it('should be dirty when a form is set dirty and no recored added to the grid', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isAdded: false
                        }, {
                            id: 2,
                            isAdded: false
                        }]
                    }
                }
            };
            c.form.$dirty = true;
            var isDirty = c.topic.isDirty();
            expect(isDirty).toBe(true);
        });
        it('should get form data for added items only when groups belongs to another', function () {
            var c = controller();
            c.displayGroups = true;
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isAdded: false
                        }, {
                            id: 2,
                            isAdded: true
                        }]
                    }
                }
            };

            var data = c.topic.getFormData().groupMembershipDelta.added;
            expect(data.length).toBe(1);
            expect(_.first(data).memberCode).toBe('AU');
            expect(_.first(data).groupCode).toBe(2);
        });
        it('should get form data for added items only when adding members of group', function () {
            var c = controller();
            c.displayGroups = false;
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isAdded: false
                        }, {
                            id: 2,
                            isAdded: true
                        }]
                    }
                }
            };

            var data = c.topic.getFormData().groupMembershipDelta.added;
            expect(data.length).toBe(1);
            expect(_.first(data).memberCode).toBe(2);
            expect(_.first(data).groupCode).toBe('AU');
        });
        it('should be dirty when a record is edited in the grid', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isEdited: false
                        }, {
                            id: 2,
                            isEdited: true
                        }]
                    }
                }
            };

            var isDirty = c.topic.isDirty();
            expect(isDirty).toBe(true);
        });
        it('should get form data for edited items only when groups belongs to another', function () {
            var c = controller();
            c.displayGroups = true;
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isEdited: false
                        }, {
                            id: 2,
                            isEdited: true
                        }]
                    }
                }
            };

            var data = c.topic.getFormData().groupMembershipDelta.updated;
            expect(data.length).toBe(1);
            expect(_.first(data).memberCode).toBe('AU');
            expect(_.first(data).groupCode).toBe(2);
        });
        it('should be dirty when a record is deleted in the grid', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            deleted: false
                        }, {
                            id: 2,
                            deleted: true
                        }]
                    }
                }
            };

            var isDirty = c.topic.isDirty();
            expect(isDirty).toBe(true);
        });
        it('should get form data for edited items only when groups belongs to another', function () {
            var c = controller();
            c.displayGroups = true;
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            deleted: false
                        }, {
                            id: 2,
                            deleted: true
                        }]
                    }
                }
            };

            var data = c.topic.getFormData().groupMembershipDelta.deleted;
            expect(data.length).toBe(1);
            expect(_.first(data).memberCode).toBe('AU');
            expect(_.first(data).groupCode).toBe(2);
        });
    });
});