describe('inprotech.configuration.general.validcombination.validCombinationMaintenanceService', function () {
    'use strict';

    var service, characterstic, entity1, entity2, modalService, validCombService, notificationService, kendoGridBuilder, objVc, scope, bulkMenuOperationsMock;

    beforeEach(function () {
        module('inprotech.configuration.general.validcombination');
        module(function ($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.validcombination', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            validCombService = $injector.get('ValidCombinationServiceMock');
            $provide.value('validCombinationService', validCombService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            bulkMenuOperationsMock = $injector.get('BulkMenuOperationsMock');
        });
    });

    beforeEach(inject(function (validCombinationMaintenanceService, $rootScope) {
        service = validCombinationMaintenanceService;
        characterstic = {
            type: 'propertyType'
        };

        scope = $rootScope.$new();
        scope.viewData = {};
        scope.selectedCharacteristics = characterstic;
        scope.vm = {
            searchCriteria: {}
        };

        entity1 = {
            id: {
                countryId: 'A',
                propertyTypeId: 'A'
            },
            countryId: 'A',
            propertyTypeId: 'A',
            selected: true
        };

        entity2 = {
            id: {
                countryId: 'B',
                propertyTypeId: 'B'
            },
            countryId: 'B',
            propertyTypeId: 'B',
            selected: true
        };

        objVc = {
            gridOptions: {
                data: function () {
                    return [entity1, entity2];
                }
            },
            actions: [{
                id: 'edit',
                maxSelection: 1
            }, {
                id: 'duplicate',
                maxSelection: 1
            }, {
                id: 'delete'
            }],
            search: function () { },
            bulkMenuOperations: bulkMenuOperationsMock.prototype
        };
        objVc.bulkMenuOperations.selectedRecord.and.returnValue(entity1);
        objVc.bulkMenuOperations.selectedRecords.and.returnValue([entity1,entity2]);
    }));

    describe('create compositeIds', function () {
        it('should create compositeids on the data', function () {
            service.prepareDataSource({data: objVc.gridOptions.data()});

            expect(objVc.gridOptions.data()[0].compositeId).toBe('--------AA-');
        });       
    });

    describe('add valid combination', function () {
        it('should call modalService and entity state should be adding', function () {
            service.add();

            expect(modalService.open).toHaveBeenCalled();
            expect(service.modalOptions.state).toBe('adding');
        });
        
        it('handleAddFromMainController should call modalService and entity state should be adding', function () {
            service.handleAddFromMainController();

            expect(modalService.open).toHaveBeenCalled();
            expect(service.modalOptions.state).toBe('adding');
        });
    });

    describe('edit valid combination', function () {
        it('should call validCombinationService get method for getting entity', function () {
            entity1.selected = true;
            service.vc = objVc;
            spyOn(validCombService, 'get').and.callThrough();            
            service.initialize(service.vc, scope);
            service.vc.actions[0].click();

            expect(validCombService.get).toHaveBeenCalledWith(entity1.id, characterstic);
        });
        it('should call modalService and entity state should be updating', function () {
            entity1.selected = true;            
            service.vc = objVc;
            service.initialize(service.vc, scope);
            service.vc.actions[0].click();

            expect(modalService.open).toHaveBeenCalled();
            expect(service.modalOptions.state).toBe('updating');
        });
    });

    describe('duplicate valid combination', function () {
        it('should call validCombinationService get method for getting entity', function () {
            entity1.selected = true;
            service.vc = objVc;
            spyOn(validCombService, 'get').and.callThrough();
            service.initialize(service.vc, scope);
            service.vc.actions[1].click();

            expect(validCombService.get).toHaveBeenCalledWith(entity1.id, characterstic);
        });
        it('should call modalService and entity state should be updating', function () {
            entity1.selected = true;
            service.vc = objVc;
            service.initialize(service.vc, scope);
            service.vc.actions[1].click();

            expect(modalService.open).toHaveBeenCalled();
            expect(service.modalOptions.state).toBe('duplicating');
        });
    });

    describe('delete valid combinations', function () {
        it('should call validCombinationService delete method', function () {
            entity1.selected = true;
            entity2.selected = false;
            objVc.bulkMenuOperations.selectedRecords.and.returnValue([entity1]);
            service.vc = objVc;

            spyOn(validCombService, 'delete').and.callThrough();
            spyOn(service.vc, 'search');
            service.initialize(service.vc, scope);
            service.vc.actions[2].click();

            expect(validCombService.delete).toHaveBeenCalledWith([entity1.id], characterstic);
            expect(notificationService.success).toHaveBeenCalled();
            expect(service.vc.search).toHaveBeenCalled();
        });

        it('should show error notification when some of the records in use', function () {
            entity1.selected = true;
            entity2.selected = true;
            service.vc = objVc;

            spyOn(validCombService, 'delete').and.callFake(function () {
                return {
                    then: function (cb) {
                        var response = {
                            data: {
                                hasError: true,
                                inUseIds: [entity1.id]
                            }
                        };
                        return cb(response);
                    }
                };
            });

            var expected = {
                title: 'modal.partialComplete',
                message: 'modal.alert.partialComplete<br/>modal.alert.alreadyInUse'
            };

            spyOn(service.vc, 'search').and.callFake(function () {
                return {
                    then: function (cb) {
                        return cb();
                    }
                };
            });

            service.initialize(service.vc, scope);
            service.vc.actions[2].click();

            expect(validCombService.delete).toHaveBeenCalled();
            expect(validCombService.delete).toHaveBeenCalledWith([entity1.id, entity2.id], characterstic);
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });

        it('should call notification alert when all records are in use', function () {
            entity1.selected = true;
            entity2.selected = true;
            service.vc = objVc;

            spyOn(validCombService, 'delete').and.callFake(function () {
                return {
                    then: function (cb) {
                        var response = {
                            data: {
                                hasError: true,
                                inUseIds: [entity1.id, entity2.id]
                            }
                        };
                        return cb(response);
                    }
                };
            });

            var expected = {
                title: 'modal.unableToComplete',
                message: 'modal.alert.alreadyInUse'
            };

            spyOn(service.vc, 'search').and.callFake(function () {
                return {
                    then: function (cb) {
                        return cb();
                    }
                };
            });

            service.initialize(service.vc, scope);
            service.vc.actions[2].click();

            expect(validCombService.delete).toHaveBeenCalled();
            expect(validCombService.delete).toHaveBeenCalledWith([entity1.id, entity2.id], characterstic);
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
    });

    describe('saved valid combination rows', function () {       
        it('clearSavedRows should clear savedKeys data', function () {
            service.savedKeys = [{
                countryId: 'A',
                propertyTypeId: 'B'
            }, {
                countryId: 'A',
                propertyTypeId: 'A'
            }];

            service.clearSavedRows();

            expect(service.savedKeys.length).toBe(0);
        });

        it('addSavedKeys should add updated keys to the list', function () {
            var updateKeys = [{
                countryId: 'A',
                propertyTypeId: 'B'
            }, {
                countryId: 'B',
                propertyTypeId: 'B'
            }];

            service.savedKeys = [{
                countryId: 'A',
                propertyTypeId: 'A'
            }];

            service.addSavedKeys(updateKeys);

            expect(service.savedKeys.length).toBe(3);
        });

        it('persistSavedData should set saved property to true', function () {
            var entities = [{
                id: {
                    countryId: 'A',
                    propertyTypeId: 'A'
                }
            }, {
                id: {
                    countryId: 'A',
                    propertyTypeId: 'B'
                }
            }, {
                id: {
                    countryId: 'B',
                    propertyTypeId: 'B'
                }
            }];

            service.savedKeys = [{
                countryId: 'A',
                propertyTypeId: 'A'
            }, {
                countryId: 'B',
                propertyTypeId: 'B'
            }];

            service.persistSavedData(entities);
            expect(entities[0].saved).toBe(true);
            expect(entities[2].saved).toBe(true);
        });
    });   
});
