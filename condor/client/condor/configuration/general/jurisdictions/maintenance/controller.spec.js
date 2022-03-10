describe('inprotech.configuration.general.jurisdictions.JurisdictionMaintenanceController', function() {
    'use strict';

    var controller, maintenanceService, notificationService, store;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.notification']);
            $provide.value('jurisdictionsService', $injector.get('JurisdictionsServiceMock'));

            maintenanceService = $injector.get('JurisdictionMaintenanceServiceMock');
            $provide.value('jurisdictionMaintenanceService', maintenanceService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            $injector = angular.injector(['inprotech.mocks']);
            store = $injector.get('storeMock');
            $provide.value('store', store);

            store.local.get.returnValue = null;
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: {}
            }, dependencies);

            return $controller('JurisdictionMaintenanceController', dependencies);
        };
    }));

    it('should initialise the view', function() {
        var viewData = {
            id: 'PCT',
            type: '1'
        };
        var c = controller({
            viewData: viewData
        });
        c.$onInit();
        expect(c.context).toBe('jurisdictions.detail');
        expect(c.defaultJurisdiction).toBe(false);
        expect(c.viewData).toBeDefined();
        expect(c.save).toBeDefined();
        expect(c.discard).toBeDefined();
        expect(c.isSaveEnabled).toBeDefined();
        expect(c.isDiscardEnabled).toBeDefined();
        expect(c.options).toBeDefined();
        expect(c.options.topics[0].viewData).toBe(viewData);
        expect(c.options.topics[1].parentId).toBe(viewData.id);
        expect(c.options.topics[1].type).toBe(viewData.type);
    });

    it('should initialise the view', function() {
        var viewData = {
            id: 'PCT',
            type: '1'
        };
        var c = controller({
            viewData: viewData
        });
        c.$onInit();
        expect(c.context).toBe('jurisdictions.detail');
        expect(c.defaultJurisdiction).toBe(false);
        expect(c.viewData).toBeDefined();
        expect(c.save).toBeDefined();
        expect(c.discard).toBeDefined();
        expect(c.isSaveEnabled).toBeDefined();
        expect(c.isDiscardEnabled).toBeDefined();
        expect(c.options).toBeDefined();
        expect(c.options.topics[0].viewData).toBe(viewData);
        expect(c.options.topics[1].parentId).toBe(viewData.id);
        expect(c.options.topics[1].type).toBe(viewData.type);
    });
    it('should set the lastSearch from the local store', function() {
        var args = ['1', '2'];
        store.local.get.returnValue = args;
        var viewData = {
            id: 'PCT',
            type: '1'
        };
        var c = controller({
            viewData: viewData
        });
        c.$onInit();
        expect(c.lastSearch.methodName).toBe('search');
        expect(c.lastSearch.args[0]).toBe('1');
        expect(c.lastSearch.args[1]).toBe('2');
    });

    describe('viewing a group jurisdiction', function() {
        var groupView = {
            id: 'EP',
            type: '1'
        };
        var c;
        beforeEach(function() {
            c = controller({
                viewData: groupView
            });
            c.$onInit();
        });
        it('should add generic topics', function() {
            expect(_.where(c.options.topics, {
                key: "overview"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "groups"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "attributes"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "texts"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "businessDays"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "validNumbers"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "defaults"
            }).length).toBe(1);
        });
        it('should add the statusflags topic if viewing a group type', function() {
            expect(c.options.topics[1].type).toBe(groupView.type);
            expect(_.where(c.options.topics, {
                key: "statusflags"
            }).length).toBe(1);
        });
        it('should not add the States and Address Settings topic if not viewing an address type', function() {
            expect(c.options.topics[1].type).toBe(groupView.type);
            expect(_.where(c.options.topics, {
                key: "states"
            }).length).toBe(0);
            expect(_.where(c.options.topics, {
                key: "addressSettings"
            }).length).toBe(0);
        });
    })

    describe('viewing an address type jurisdiction', function() {
        var addressView = {
            id: 'AU',
            type: '0'
        };
        var c;
        beforeEach(function() {
            c = controller({
                viewData: addressView
            });
            c.$onInit();
        });
        it('should add generic topics', function() {
            expect(_.where(c.options.topics, {
                key: "overview"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "groups"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "attributes"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "texts"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "businessDays"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "validNumbers"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "defaults"
            }).length).toBe(1);
        });
        it('should not add the statusflags topic if not viewing a group type', function() {
            expect(c.options.topics[1].type).toBe(addressView.type);
            expect(_.where(c.options.topics, {
                key: "statusflags"
            }).length).toBe(0);
        });
        it('should add the States and Address Settings topics if viewing an address type', function() {
            expect(c.options.topics[1].type).toBe(addressView.type);
            expect(_.where(c.options.topics, {
                key: "states"
            }).length).toBe(1);
            expect(_.where(c.options.topics, {
                key: "addressSettings"
            }).length).toBe(1);
        });
    })

    describe('saving', function() {
        it('should call service and display notification', function() {
            maintenanceService.save.returnValue = {};

            var c = controller({
                viewData: {
                    id: 'AU',
                    type: '0'
                }
            });
            c.$onInit();
            var overview = c.options.topics[0];
            overview.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var groups = c.options.topics[1];
            groups.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var attributes = c.options.topics[2];
            attributes.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var texts = c.options.topics[3];
            texts.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var classes = c.options.topics[4];
            classes.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var defaults = c.options.topics[8];
            defaults.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var states = c.options.topics[5];
            states.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var validNumbers = c.options.topics[9];
            validNumbers.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var addressSettings = c.options.topics[7];
            addressSettings.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});
            var businessDays = c.options.topics[6];
            businessDays.getFormData = jasmine.createSpy('getFormData() spy').and.returnValue({});

            c.save();
            expect(overview.getFormData).toHaveBeenCalled();
            expect(groups.getFormData).toHaveBeenCalled();
            expect(attributes.getFormData).toHaveBeenCalled();
            expect(texts.getFormData).toHaveBeenCalled();
            expect(classes.getFormData).toHaveBeenCalled();
            expect(states.getFormData).toHaveBeenCalled();
            expect(validNumbers.getFormData).toHaveBeenCalled();
            expect(addressSettings.getFormData).toHaveBeenCalled();
            expect(businessDays.getFormData).toHaveBeenCalled();
            expect(maintenanceService.save).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
        });
    })

    describe('discarding', function() {
        it('should call section discard', function() {
            var c = controller({
                viewData: {
                    id: 'EP',
                    type: '1'
                }
            });
            c.$onInit();
            var overview = c.options.topics[0];
            overview.discard = jasmine.createSpy('discard() spy').and.callThrough();
            var groups = c.options.topics[1];
            groups.discard = jasmine.createSpy('discard() spy').and.callThrough();
            var attributes = c.options.topics[2];
            attributes.discard = jasmine.createSpy('discard() spy').and.callThrough();
            var texts = c.options.topics[3];
            texts.discard = jasmine.createSpy('discard() spy').and.callThrough();

            c.discard();
            expect(c.isSaveEnabled()).toBe(false);
        })
    })

    describe('isSaveEnabled returns', function() {
        var c, overview, groups, attributes, texts, statusflags, classes, defaults, businessDays, validNumbers;
        beforeEach(function() {
            c = controller({
                viewData: {
                    id: 'EP',
                    type: '1'
                }
            });
            c.$onInit();
            overview = c.options.topics[0];
            overview.initialised = true;

            groups = c.options.topics[1];
            groups.initialised = true;

            attributes = c.options.topics[2];
            attributes.initialised = true;

            texts = c.options.topics[3];
            texts.initialised = true;

            statusflags = c.options.topics[4];
            statusflags.initialised = true;

            classes = c.options.topics[5];
            classes.initialised = true;

            businessDays = c.options.topics[6];
            businessDays.initialised = true;

            defaults = c.options.topics[7];
            defaults.initialised = true;

            validNumbers = c.options.topics[8];
            validNumbers.initialised = true;
        });
        it('false if not initialised', function() {
            overview.initialised = false;
            groups.initialised = false;
            attributes.initialised = false;
            texts.initialised = false;
            statusflags.initialised = false;
            classes.initialised = false;
            validNumbers.initialised = false;
            expect(c.isSaveEnabled()).toBe(false);
        });
        it('false if there are errors', function() {
            overview.hasError = jasmine.createSpy('hasError() spy').and.returnValue(true);
            overview.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            expect(c.isSaveEnabled()).toBe(false);
        });
        it('false if there are no pending changes', function() {
            overview.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            overview.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            groups.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            groups.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            attributes.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            attributes.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            texts.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            texts.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            statusflags.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            statusflags.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            classes.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            classes.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            defaults.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            defaults.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            validNumbers.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            validNumbers.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            businessDays.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            businessDays.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            expect(c.isSaveEnabled()).toBe(false);
        });
        it('true if there are no errors and there are pending changes', function() {
            overview.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            overview.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            groups.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            groups.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            attributes.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            attributes.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            texts.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            texts.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            statusflags.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            statusflags.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            classes.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            classes.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            defaults.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            defaults.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            validNumbers.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            validNumbers.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            businessDays.hasError = jasmine.createSpy('hasError() spy').and.returnValue(false);
            businessDays.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            expect(c.isSaveEnabled()).toBe(true);
        });
    })

    describe('isDiscardEnabled returns', function() {
        var c, overview, groups, attributes, texts, statusflags, classes, defaults, businessDays, validNumbers;
        beforeEach(function() {
            c = controller({
                viewData: {
                    id: 'EP',
                    type: '1'
                }
            });
            c.$onInit();
            overview = c.options.topics[0];
            overview.initialised = true;
            groups = c.options.topics[1];
            groups.initialised = true;
            attributes = c.options.topics[2];
            attributes.initialised = true;
            texts = c.options.topics[3];
            texts.initialised = true;
            statusflags = c.options.topics[4];
            statusflags.initialised = true;
            classes = c.options.topics[5];
            classes.initialised = true;
            businessDays = c.options.topics[6];
            businessDays.initialised = true;
            defaults = c.options.topics[7];
            defaults.initialised = true;
            validNumbers = c.options.topics[8];
            validNumbers.initialised = true;
        });
        it('false if not initialised', function() {
            overview.initialised = false;
            groups.initialised = false;
            attributes.initialised = false;
            texts.initialised = false;
            statusflags.initialised = false;
            classes.initialised = false;
            validNumbers.initialised = false;
            expect(c.isDiscardEnabled()).toBe(false);
        });
        it('false if there are no pending changes', function() {
            overview.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            groups.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            attributes.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            texts.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            statusflags.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            classes.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            defaults.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            validNumbers.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            businessDays.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(false);
            expect(c.isDiscardEnabled()).toBe(false);
        });
        it('true if there are no errors and there are pending changes', function() {
            overview.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            groups.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            attributes.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            texts.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            statusflags.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            classes.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            defaults.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            validNumbers.isDirty = jasmine.createSpy('isDirty() spy').and.returnValue(true);
            expect(c.isDiscardEnabled()).toBe(true);
        });
    })

    describe('setInUse ', function() {
        var c;
        beforeEach(function() {
            c = controller({
                viewData: {
                    id: 'EP',
                    type: '0'
                }
            });
            c.$onInit();
        });
        it('should not call the topics setInUse if saveResposne is null', function() {
            var overview = c.options.topics[0];
            overview.setInUseError = jasmine.createSpy();
            c.setInUse(null);
            expect(overview.setInUseError).not.toHaveBeenCalled();
        });
        it('should call the topics setInUse', function() {
            var saveResponse = [{
                topicName: "states",
                inUseItems: [{
                        id: 1
                    },
                    {
                        id: 2
                    }
                ]
            }];

            var groups = _.find(c.options.topics, function(i) {
                return (i.key === "states")
            });
            groups.setInUseError = jasmine.createSpy();
            c.setInUse(saveResponse);
            expect(groups.setInUseError).toHaveBeenCalled();
        });
    })
});