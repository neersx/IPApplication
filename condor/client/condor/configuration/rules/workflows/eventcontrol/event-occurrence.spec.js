describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlEventOccurrence', function () {
    'use strict';

    var controller, kendoGridBuilder, service, charsService, inlineEdit, workflowCharsService;

    beforeEach(function () {
        module('inprotech.configuration.rules.workflows');
        module(function () {
            kendoGridBuilder = test.mock('kendoGridBuilder');
            service = test.mock('workflowsEventControlService');
            charsService = test.mock('caseValidCombinationService');
            workflowCharsService = test.mock('workflowsCharacteristicsService');
            inlineEdit = {
                defineModel: jasmine.createSpy()
            };
        });
    });

    beforeEach(inject(function ($rootScope, $componentController) {
        controller = function (viewData) {
            var scope = $rootScope.$new();
            var data = _.extend({}, {
                criteriaId: -111,
                eventId: -222,
                canEdit: true,
                hasOffices: true,
                eventOccurrence: {
                    characteristics: {}
                },
                dueDateCalcSettings: {},
                parent: {
                    eventOccurrence: {
                        characteristics: {}
                    }
                }
            }, viewData);
            var topic = {
                params: {
                    viewData: data
                }
            };
            var c = $componentController('ipWorkflowsEventControlEventOccurrence', {
                $scope: scope,
                kendoGridBuilder: kendoGridBuilder,
                workflowsEventControlService: service,
                inlineEdit: inlineEdit,
                caseValidCombinationService: charsService,
                workflowsCharacteristicsService: workflowCharsService
            }, {
                topic: topic
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialisation', function () {
        it('initialises', function () {
            var data = {
                eventOccurrence: {
                    characteristics: {
                        office: { key: 123 }
                    }
                }
            };
            var c = controller(data);

            expect(c.criteriaId).toEqual(-111);
            expect(c.eventId).toEqual(-222);
            expect(c.canEdit).toEqual(true);
            expect(c.hasOffices).toEqual(true);
            expect(c.formData.characteristics.office.key).toEqual(123);
            expect(c.matchBoxChanged).toBeDefined();
            expect(charsService.initFormData).toHaveBeenCalledWith(c.formData.characteristics);
            expect(charsService.addExtendFunctions).toHaveBeenCalledWith(c);
            expect(c.isCharacteristicInherited).toBeDefined();
            expect(c.onNameTypeChanged).toBeDefined();
            expect(c.markDuplicated).toBeDefined();
            expect(c.validateValidCombinations).toBeDefined();
            expect(c.isEventOccurrenceDisabled).toBeDefined();
            expect(c.isWhenAnotherCaseExistsDisabled).toBeDefined();

            expect(c.topic.getFormData).toBeDefined();
            expect(c.topic.hasError).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.validate).toBeDefined();
        });

        it('initialises due date occurs setting', function () {
            var c = controller();
            expect(c.formData.dueDateOccurs).toEqual('NotApplicable');

            c = controller({
                eventOccurrence: {
                    characteristics: {},
                    dueDateOccurs: 'blah'
                }
            });
            expect(c.formData.dueDateOccurs).toEqual('blah');
        });

        it('initialises When another case exists check box', function () {
            var c = controller();
            expect(c.isWhenAnotherCaseExists).toEqual(false);

            c = controller({
                eventOccurrence: {
                    matchOffice: true,
                    characteristics: {}
                }
            });
            expect(c.isWhenAnotherCaseExists).toEqual(true);

            c = controller({
                eventOccurrence: {
                    characteristics: {},
                    eventsExist: [{ 'a': 'b' }]
                }
            });
            expect(c.isWhenAnotherCaseExists).toEqual(true);

            c = controller({
                eventOccurrence: {
                    characteristics: {
                        subType: { key: 'a' }
                    }
                }
            });
            expect(c.isWhenAnotherCaseExists).toEqual(true);
        });
    });

    describe('disabling fields', function () {
        it('disables when another case exists when not applicable is selected', function () {
            var c = controller();
            c.formData.dueDateOccurs = 'NotApplicable';
            expect(c.isWhenAnotherCaseExistsDisabled()).toEqual(true);

            c.formData.dueDateOccurs = 'blah';
            expect(c.isWhenAnotherCaseExistsDisabled()).toEqual(false);
        });

        it('disables entire section when extend due date is selcted in due date calc settings', function () {
            var c = controller({
                dueDateCalcSettings: {
                    extendDueDate: true
                }
            });
            expect(c.isEventOccurrenceDisabled()).toEqual(true);
        });
    });

    describe('inheritance highlighting', function () {
        it('highlights if all characteristics and match flags are equal', function () {
            var parentData = {
                isInherited: true,
                eventOccurrence: {
                    matchOffice: true,
                    matchJurisdiction: true,
                    matchPropertyType: true,
                    matchCaseCategory: true,
                    matchSubType: true,
                    matchBasis: true,
                    characteristics: {
                        office: { key: 'office' },
                        caseType: { key: 'case type' },
                        jurisdiction: { code: 'jurisdiction' },
                        propertyType: { code: 'property type' },
                        caseCategory: { code: 'case category' },
                        subType: { code: 'sub type' },
                        basis: { code: 'basis' }
                    }
                }
            };

            var data = {
                isInherited: true,
                parent: parentData,
                eventOccurrence: {
                    matchOffice: true,
                    matchJurisdiction: true,
                    matchPropertyType: true,
                    matchCaseCategory: true,
                    matchSubType: true,
                    matchBasis: true,
                    characteristics: {
                        office: { key: 'office' },
                        caseType: { key: 'case type' },
                        jurisdiction: { code: 'jurisdiction' },
                        propertyType: { code: 'property type' },
                        caseCategory: { code: 'case category' },
                        subType: { code: 'sub type' },
                        basis: { code: 'basis' }
                    }
                }
            };

            var c = controller(data);

            expect(c.isCharacteristicInherited()).toEqual(true);

            c.formData.matchBasis = false;
            expect(c.isCharacteristicInherited()).toEqual(false);
            c.formData.matchBasis = true;

            c.formData.characteristics.office.key = 'officeX';
            expect(c.isCharacteristicInherited()).toEqual(false);
            c.formData.characteristics.office.key = 'office';

            expect(c.isCharacteristicInherited()).toEqual(true);
        })
    });

    describe('match box change handling', function () {
        it('should set picklists to null when match ticked', function () {
            var c = controller({
                eventOccurrence: {
                    matchOffice: true,
                    matchJurisdiction: true,
                    matchPropertyType: true,
                    matchCaseCategory: true,
                    matchSubType: true,
                    matchBasis: true,
                    characteristics: {
                        office: 'office',
                        jurisdiction: 'jurisdiction',
                        propertyType: 'property type',
                        caseCategory: 'case category',
                        subType: 'sub type',
                        basis: 'basis'
                    }
                }
            });
            workflowCharsService.validate = jasmine.createSpy();
            c.form = {};
            c.matchBoxChanged();
            expect(c.formData.characteristics.office).toBe(null);
            expect(c.formData.characteristics.jurisdiction).toBe(null);
            expect(c.formData.characteristics.propertyType).toBe(null);
            expect(c.formData.characteristics.caseCategory).toBe(null);
            expect(c.formData.characteristics.subType).toBe(null);
            expect(c.formData.characteristics.basis).toBe(null);
            expect(workflowCharsService.validate).toHaveBeenCalledWith(c.formData.characteristics, c.form);
        });
    });

    describe('duplicate name type checking', function () {
        it('sets duplicate flag when name type is duplicated', function () {
            var c = controller();
            var row = {
                nameType: {
                    $setValidity: jasmine.createSpy()
                }
            };
            var item = {
                nameType: {
                    code: 'A'
                }
            };

            c.gridOptions = {
                dataSource: {
                    data: jasmine.createSpy().and.returnValue([{ nameType: { code: 'A' } }])
                }
            };

            c.onNameTypeChanged(item, row);
            expect(row.nameType.$setValidity).toHaveBeenCalledWith('eventcontrol.eventOccurrence.nameTypeMapped', true);
            expect(item.isDuplicatedRecord).toEqual(true);
        });

        it('performs a duplicate check on validate', function () {
            var c = controller();
            c.form = {
                $validate: jasmine.createSpy().and.returnValue(true)
            };
            var gridData = [{ nameType: { code: 'A' } }, { nameType: { code: 'B' } }, { nameType: { code: 'A' } }];
            c.gridOptions = {
                dataSource: {
                    data: jasmine.createSpy().and.returnValue(gridData)
                }
            };

            var result = c.topic.validate();

            expect(c.form.$validate).toHaveBeenCalled();
            expect(result).toEqual(false);
            expect(gridData[2].isDuplicatedRecord).toEqual(true);
        });
    });

    describe('get form data for save', function () {
        it('sets update event options', function () {
            var c = controller();
            c.formData.dueDateOccurs = 'Immediate';
            var result = c.topic.getFormData();

            expect(result.updateEventImmediate).toEqual(true);
            expect(result.updateEventWhenDue).toEqual(false);

            c.formData.dueDateOccurs = 'OnDueDate';
            result = c.topic.getFormData();
            expect(result.updateEventImmediate).toEqual(false);
            expect(result.updateEventWhenDue).toEqual(true);
        });

        it('sets case match data if \"When Another Case Exists\" is ticked', function () {
            var originalEventList = [{ key: 'Z' }, { key: 'deleteMe' }];
            var c = controller(
                {
                    eventOccurrence: {
                        matchOffice: false,
                        matchPropertyType: true,
                        characteristics: {
                            office: { key: 'office' },
                            caseType: { code: 'case type' },
                            basis: { code: 'basis' }
                        },
                        eventsExist: originalEventList
                    }
                }
            );
            c.isWhenAnotherCaseExists = true;

            var gridData = [{ nameType: { code: 'A' } }, { nameType: { code: 'B' } }];
            c.gridOptions = {
                dataSource: {
                    data: jasmine.createSpy().and.returnValue(gridData)
                }
            };

            c.formData.eventsExist = [{ key: 'Z' }, { key: 'added' }];

            var result = c.topic.getFormData();
            expect(result.officeId).toEqual('office');
            expect(result.officeIsThisCase).toEqual(false);
            expect(result.caseTypeId).toEqual('case type');
            expect(result.propertyTypeIsThisCase).toEqual(true);
            expect(result.basisId).toEqual('basis');

            expect(service.mapGridDelta).toHaveBeenCalledWith(gridData, jasmine.any(Function));
            expect(result.requiredEventRulesDelta.added[0]).toEqual('added');
            expect(result.requiredEventRulesDelta.deleted[0]).toEqual('deleteMe');
        });

        it('deletes case match data if \"When Another Case Exists\" is unticked', function () {
            var originalEventList = [{ key: 'Z' }, { key: 'Y' }];
            var c = controller(
                {
                    eventOccurrence: {
                        characteristics: {},
                        eventsExist: originalEventList
                    }
                }
            );
            c.isWhenAnotherCaseExists = false;
            c.formData.characteristics.office = { key: 'A' };

            var gridData = [{ nameType: { code: 'A' } }, { nameType: { code: 'B' } }];
            c.gridOptions = {
                dataSource: {
                    data: jasmine.createSpy().and.returnValue(gridData)
                }
            };

            var result = c.topic.getFormData();

            expect(gridData[0].deleted).toEqual(true);
            expect(gridData[1].deleted).toEqual(true);
            expect(service.mapGridDelta).toHaveBeenCalled();

            expect(result.requiredEventRulesDelta.added.length).toEqual(0);
            expect(result.requiredEventRulesDelta.deleted.length).toEqual(2);
            expect(result.officeId).toBeUndefined();
        });

        it('converts name type data for save', function () {
            var c = controller();

            var convertMethod;
            service.mapGridDelta = jasmine.createSpy().and.callFake(function (arg1, arg2) {
                convertMethod = arg2;
            });
            c.topic.getFormData();

            var result = convertMethod({
                sequence: 9,
                nameType: { code: 'nameTypeCode' },
                caseNameType: { code: 'caseNameTypeCode' },
                mustExist: 'Anthony was here'
            });

            expect(result.sequence).toEqual(9);
            expect(result.applicableNameTypeKey).toEqual('nameTypeCode');
            expect(result.substituteNameTypeKey).toEqual('caseNameTypeCode');
            expect(result.mustExist).toEqual('Anthony was here');
        });
    });
});