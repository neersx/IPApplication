describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlDesignatedJurisdictions', function() {
    'use strict';

    var controller, kendoGridBuilder, kendoGridService, service, topic, picklistService, promiseMock;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            kendoGridBuilder = test.mock('kendoGridBuilder');
            service = test.mock('workflowsEventControlService');
            kendoGridService = test.mock('kendoGridService');
            picklistService = test.mock('picklistService');
            promiseMock = test.mock('promise');
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            var scope = $rootScope.$new();
            topic = {
                params: {
                    viewData: {
                        criteriaId: -111,
                        eventId: -222,
                        canEdit: true,
                        designatedJurisdictions: {
                            countryFlagForStopReminders: 32,
                            countryFlags: [{
                                key: 1,
                                value: "Select at Application"
                            }, {
                                key: 2,
                                value: "Elect Preliminary Examination"
                            }]
                        },
                        characteristics: {
                            jurisdiction: {
                                key: 'a',
                                value: 'ajurisdiction'
                            }
                        },
                        isInherited: true,
                        parent: {
                            designatedJurisdictions: 'abc'
                        }
                    }
                }
            };
            var c = $componentController('ipWorkflowsEventControlDesignatedJurisdictions', {
                $scope: scope,
                kendoGridBuilder: kendoGridBuilder,
                kendoGridService: kendoGridService,
                workflowsEventControlService: service
            }, {
                topic: topic
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();

            expect(c.topic.validate).toBeDefined();
            expect(c.topic.hasError).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.getFormData).toBeDefined();
            expect(c.canEdit).toBe(true);
            expect(c.selectedCountryFlag).toBe(32);
            expect(c.countryFlags).toBe(topic.params.viewData.designatedJurisdictions.countryFlags);
            expect(c.gridOptions).toBeDefined();
            expect(c.onAddClick).toBeDefined()
            expect(c.groupName).toBe('ajurisdiction');
            expect(c.groupKey).toBe('a');
            expect(c.parentData).toEqual('abc');
        });
    });

    describe('onAddClick', function() {
        it('should open the designated jurisdiction modal and set the data', function() {
            var c = controller();

            c.form = {
                selectedCountryFlag: null
            };

            var selections = [{
                value: 'b'
            }, {
                value: 'c'
            }, {
                value: 'a'
            }];
            picklistService.openModal = promiseMock.createSpy(selections);
            kendoGridService.activeData.returnValue = {
                'abc': 'def'
            };

            c.onAddClick();
            expect(picklistService.openModal).toHaveBeenCalledWith(jasmine.any(Object),
                jasmine.objectContaining({
                    apiUrl: 'api/picklists/designatedjurisdictions?groupId=a',
                    multipick: true,
                    selectedItems: {
                        'abc': 'def'
                    }
                }));
            expect(kendoGridService.sync).toHaveBeenCalledWith(c.gridOptions, [{
                value: 'a'
            }, {
                value: 'b'
            }, {
                value: 'c'
            }]);
        });
    });

    describe('dirty check', function() {
        it('should return dirty if form or grid is dirty', function() {
            var c = controller();

            c.form = {
                $dirty: false
            };
            kendoGridService.isGridDirty.returnValue = false;

            expect(c.topic.isDirty()).toBe(false);

            c.form.$dirty = true;
            expect(c.topic.isDirty()).toBe(true);

            c.form.$dirty = false;
            kendoGridService.isGridDirty.returnValue = true;
            expect(c.topic.isDirty()).toBe(true);
        })
    });

    describe('get form data', function() {
        it('should return form data and grid delta', function() {
            var c = controller();
            service.mapGridDelta.returnValue = 'abc';

            var result = c.topic.getFormData();

            expect(kendoGridService.data).toHaveBeenCalled();
            expect(result.countryFlagForStopReminders).toBe(32);
            expect(result.designatedJurisdictionsDelta).toBe('abc');
        });
    });

    describe('hasError', function() {
        it('returns if the form is in an invalid state', function() {
            var c = controller();
            c.form = {
                $invalid: false
            };
            expect(c.topic.hasError()).toBe(false);

            c.form.$invalid = true;
            expect(c.topic.hasError()).toBe(true);

        });
    });

    describe('validate', function() {
        it('should return valid if stop calculating stage and designated jurisdictions empty', function() {
            var c = controller();
            c.form = {
                selectedCountryFlag: {
                    $setValidity: jasmine.createSpy()
                },
                $invalid: false
            };
            kendoGridService.hasActiveItems.returnValue = false;
            c.selectedCountryFlag = null;

            expect(c.topic.validate()).toBe(true);
            expect(c.form.selectedCountryFlag.$setValidity).toHaveBeenCalledWith('eventcontrol.designatedJurisdiction.missingStage', true);
            expect(c.form.selectedCountryFlag.$setValidity).toHaveBeenCalledWith('eventcontrol.designatedJurisdiction.missingDesignatedJurisdiction', true);
        });

        it('should return invalid if only one item is entered', function() {
            var c = controller();
            c.form = {
                selectedCountryFlag: {
                    $setValidity: jasmine.createSpy()
                },
                $invalid: true
            };
            kendoGridService.hasActiveItems.returnValue = false;
            c.selectedCountryFlag = 1;

            expect(c.topic.validate()).toBe(false);
            expect(c.form.selectedCountryFlag.$setValidity).toHaveBeenCalledWith('eventcontrol.designatedJurisdiction.missingStage', true);
            expect(c.form.selectedCountryFlag.$setValidity).toHaveBeenCalledWith('eventcontrol.designatedJurisdiction.missingDesignatedJurisdiction', false);

            kendoGridService.hasActiveItems.returnValue = true;
            c.selectedCountryFlag = null;
            expect(c.topic.validate()).toBe(false);
            expect(c.form.selectedCountryFlag.$setValidity).toHaveBeenCalledWith('eventcontrol.designatedJurisdiction.missingStage', false);
            expect(c.form.selectedCountryFlag.$setValidity).toHaveBeenCalledWith('eventcontrol.designatedJurisdiction.missingDesignatedJurisdiction', true);
        });
    });
});
