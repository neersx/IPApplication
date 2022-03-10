describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlNameChange', function() {
    'use strict';

    var controller;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function(nameChangeSettings, formSetting) {
            var scope = $rootScope.$new();
            var topic = {
                params: {
                    viewData: {
                        canEdit: true,
                        nameChangeSettings: nameChangeSettings,
                        isInherited: true,
                        parent: {
                            nameChangeSettings: 'abc'
                        }
                    }
                }
            };
            var ctrl = $componentController('ipWorkflowsEventControlNameChange', {
                $scope: scope
            }, {
                topic: topic
            });
            ctrl.$onInit();
            ctrl.form = formSetting;
            return ctrl;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var nameChangeSettings = {
                changeNameType: {
                    key: -111
                },
                copyFromNameType: {
                    key: -222
                },
                deleteCopyFromName: true,
                moveOldNameToNameType: {
                    key: -333
                }
            };
            var c = controller(nameChangeSettings);

            expect(c.formData.changeNameType.key).toEqual(-111);
            expect(c.formData.copyFromNameType.key).toEqual(-222);
            expect(c.formData.moveOldNameToNameType.key).toEqual(-333);
            expect(c.formData.deleteCopyFromName).toEqual(true);
            expect(c.parentData).toEqual('abc');
        });

        it('should have disabled and non-required state based on loading data', function() {
            var nameChangeSettings = {
                changeNameType: null,
                copyFromNameType: null,
                deleteCopyFromName: true,
                moveOldNameToNameType: null
            };
            var c = controller(nameChangeSettings);

            expect(c.shouldCopyFromNameTypeRequired).toEqual(false);
            expect(c.shouldCopyFromNameTypeDisabled).toEqual(true);
            expect(c.shouldMoveOldNameToNameTypeDisabled).toEqual(true);
            expect(c.shouldDeleteCopyFromNameDisabled).toEqual(true);
        });

        it('should have enabled and required state based on loading data', function() {
            var nameChangeSettings = {
                changeNameType: {
                    key: -111,
                    code: 'A',
                    value: 'type a'
                },
                copyFromNameType: {
                    key: -222,
                    code: 'B',
                    value: 'type b'
                },
                deleteCopyFromName: false,
                moveOldNameToNameType: {
                    key: -333,
                    code: 'C',
                    value: 'type c'
                }
            };
            var c = controller(nameChangeSettings);

            expect(c.shouldCopyFromNameTypeRequired).toEqual(true);
            expect(c.shouldCopyFromNameTypeDisabled).toEqual(false);
            expect(c.shouldMoveOldNameToNameTypeDisabled).toEqual(false);
            expect(c.shouldDeleteCopyFromNameDisabled).toEqual(false);
        });
    });

    describe('dynamic label translation', function() {
        it('should return static translation keys when no name types', function() {
            var nameChangeSettings = {
                changeNameType: {
                    key: -111
                },
                copyFromNameType: {
                    key: -222
                },
                deleteCopyFromName: true,
                moveOldNameToNameType: {
                    key: -333
                }
            };
            var c = controller(nameChangeSettings);
            c.formData.changeNameType = null;
            c.formData.copyFromNameType = null;

            expect(c.deleteFromTranslationKey()).toEqual('workflows.eventcontrol.nameChange.andDeleteName');
            expect(c.moveNameTranslationKey()).toEqual('workflows.eventcontrol.nameChange.moveOriginalNameTo');
        });

        it('should return dynamic translation keys when name types', function() {
            var nameChangeSettings = {
                changeNameType: {
                    key: -111
                },
                copyFromNameType: {
                    key: -222
                },
                deleteCopyFromName: true,
                moveOldNameToNameType: {
                    key: -333
                }
            };
            var c = controller(nameChangeSettings);
            c.formData.changeNameType.value = 'a';
            c.formData.copyFromNameType.value = 'a';

            expect(c.deleteFromTranslationKey()).toEqual('workflows.eventcontrol.nameChange.andDeleteNameDynamic');
            expect(c.moveNameTranslationKey()).toEqual('workflows.eventcontrol.nameChange.moveOriginalNameToDynamic');
        });
    });

    describe('state of required and disabled', function() {
        var nameChangeSettings;
        beforeEach(function() {
            nameChangeSettings = {
                changeNameType: {
                    key: -111,
                    code: 'A',
                    value: 'type a'
                },
                copyFromNameType: {
                    key: -222,
                    code: 'B',
                    value: 'type b'
                },
                deleteCopyFromName: false,
                moveOldNameToNameType: {
                    key: -333,
                    code: 'C',
                    value: 'type c'
                }
            };
        });

        it('copyFromNameType should change state', function() {
            var formSetting = {
                copyFromNameType: {
                    $dirty: true
                }
            };
            var c = controller(nameChangeSettings, formSetting);
            c.shouldCopyFromNameTypeDisabled = true;

            c.isCopyFromNameTypeDisabled();

            expect(c.form.copyFromNameType.$dirty).toEqual(false);
        });

        it('deleteCopyFromName should change state', function() {
            var formSetting = {
                deleteCopyFromName: {
                    $dirty: true
                }
            };
            var c = controller(nameChangeSettings, formSetting);
            c.shouldDeleteCopyFromNameDisabled = true;

            c.isDeleteCopyFromNameDisabled();

            expect(c.form.deleteCopyFromName.$dirty).toEqual(false);
        });

        it('isMoveOldNameToNameTypeDisabled should change state', function() {
            var formSetting = {
                moveOldNameToNameType: {
                    $dirty: true
                }
            };
            var c = controller(nameChangeSettings, formSetting);
            c.shouldMoveOldNameToNameTypeDisabled = true;

            c.isMoveOldNameToNameTypeDisabled();

            expect(c.form.moveOldNameToNameType.$dirty).toEqual(false);
        });
    });

    describe('onChangeOfChangeNameType should change state of required and disabled', function() {
        it('when changeNameType is empty', function() {
            var nameChangeSettings = {
                changeNameType: null,
                copyFromNameType: {
                    key: -222,
                    code: 'B',
                    value: 'type b'
                },
                deleteCopyFromName: false,
                moveOldNameToNameType: {
                    key: -333,
                    code: 'C',
                    value: 'type c'
                }
            };
            var c = controller(nameChangeSettings);
            c.onChangeOfCopyFromNameType = jasmine.createSpy();
            c.onChangeOfChangeNameType();

            expect(c.onChangeOfCopyFromNameType).toHaveBeenCalled();
            expect(c.formData.copyFromNameType).toEqual(null);
            expect(c.formData.moveOldNameToNameType).toEqual(null);
            expect(c.shouldCopyFromNameTypeRequired).toEqual(false);
            expect(c.shouldMoveOldNameToNameTypeDisabled).toEqual(true);
            expect(c.shouldCopyFromNameTypeDisabled).toEqual(true);
        });

        it('when changeNameType is not empty', function() {
            var nameChangeSettings = {
                changeNameType: {
                    key: -111,
                    code: 'A',
                    value: 'type a'
                },
                copyFromNameType: {
                    key: -222,
                    code: 'B',
                    value: 'type b'
                },
                deleteCopyFromName: false,
                moveOldNameToNameType: {
                    key: -333,
                    code: 'C',
                    value: 'type c'
                }
            };
            var c = controller(nameChangeSettings);
            c.onChangeOfCopyFromNameType = jasmine.createSpy();
            c.onChangeOfChangeNameType();

            expect(c.onChangeOfCopyFromNameType).toHaveBeenCalled();
            expect(c.formData.copyFromNameType.code).toEqual('B');
            expect(c.formData.moveOldNameToNameType.code).toEqual('C');
            expect(c.shouldCopyFromNameTypeRequired).toEqual(true);
            expect(c.shouldMoveOldNameToNameTypeDisabled).toEqual(false);
            expect(c.shouldCopyFromNameTypeDisabled).toEqual(false);
        });
    });

    describe('onChangeOfCopyFromNameType should change state of required and disabled', function() {
        it('when copyFromNameType is empty', function() {
            var nameChangeSettings = {
                changeNameType: {
                    key: -111,
                    code: 'A',
                    value: 'type a'
                },
                copyFromNameType: null,
                deleteCopyFromName: true,
                moveOldNameToNameType: {
                    key: -333,
                    code: 'C',
                    value: 'type c'
                }
            };
            var c = controller(nameChangeSettings);
            c.onChangeOfCopyFromNameType();

            expect(c.formData.deleteCopyFromName).toEqual(false);
            expect(c.shouldDeleteCopyFromNameDisabled).toEqual(true);
        });

        it('when copyFromNameType is not empty', function() {
            var nameChangeSettings = {
                changeNameType: {
                    key: -111,
                    code: 'A',
                    value: 'type a'
                },
                copyFromNameType: {
                    key: -222,
                    code: 'B',
                    value: 'type b'
                },
                deleteCopyFromName: true,
                moveOldNameToNameType: {
                    key: -333,
                    code: 'C',
                    value: 'type c'
                }
            };
            var c = controller(nameChangeSettings);
            c.onChangeOfCopyFromNameType();

            expect(c.formData.deleteCopyFromName).toEqual(true);
            expect(c.shouldDeleteCopyFromNameDisabled).toEqual(false);
        });
    });

    describe('isInherited method', function() {
        it('should compare form data with parent data', function() {
            var c = controller({'abc':'def'});
            c.parentData = _.clone(c.formData);
            expect(c.isInherited()).toEqual(true);

            c.formData.abc = 'xyz';
            expect(c.isInherited()).toEqual(false);
        })
    });
});
