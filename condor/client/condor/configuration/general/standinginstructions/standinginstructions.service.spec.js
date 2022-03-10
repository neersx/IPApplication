describe('inprotech.configuration.general.standinginstructions.StandingInstructionsService', function() {
    'use strict';

    var service, httpMock, ArrayExt, ObjectExt;
    var returnValue = {
        instructions: [{}, {}, {}],
        characteristics: [{}, {}, {}]
    };

    beforeEach(function() {
        module('inprotech.configuration.general.standinginstructions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');

            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(StandingInstructionsService, _ArrayExt_, _ObjectExt_) {
        service = new StandingInstructionsService();
        ArrayExt = _ArrayExt_;
        ObjectExt = _ObjectExt_;
    }));

    describe('searching', function() {
        it('should call to get details on instruction type selection', function() {
            httpMock.get.returnValue = _.clone(returnValue);
            service.search(1);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/instructiontypedetails/1');
        });

        it('should return set instructions for selected instruction type', function() {
            httpMock.get.returnValue = _.clone(returnValue);

            var searchData = service.search(1);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/instructiontypedetails/1');
            expect(searchData.instructions).toBeDefined();
            expect(searchData.instructions.items.length).toBe(3);
        });

        it('should return set characteristics for selected instruction type', function() {
            httpMock.get.returnValue = _.clone(returnValue);

            var searchData = service.search(1);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/instructiontypedetails/1');
            expect(searchData.characteristics).toBeDefined();
            expect(searchData.characteristics.items.length).toBe(3);
        });

        it('should return data in transformed format', function() {
            httpMock.get.returnValue = _.clone(returnValue);

            var searchData = service.search(1);
            expect(searchData.characteristics instanceof ArrayExt).toBe(true);
            expect(searchData.instructions instanceof ArrayExt).toBe(true);

            expect(_.first(searchData.characteristics.items) instanceof ObjectExt).toBe(true);
            expect(_.first(searchData.instructions.items) instanceof ObjectExt).toBe(true);
        });
    });

    describe('save changes', function() {
        var instrType, returnValueAfterSave;

        beforeEach(function() {
            returnValueAfterSave = {
                result: 'success',
                data: returnValue
            };

            instrType = {
                id: 1,
                instructions: {
                    added: [],
                    updated: [],
                    deleted: []
                },
                characteristics: {
                    added: [],
                    updated: [],
                    deleted: []
                }
            };
        });

        it('should call to save instruction type details', function() {
            httpMock.post.returnValue = _.clone(returnValue);
            service.saveChanges(instrType);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/instructiontypedetails/save', {
                instrType: instrType

            });
        });

        it('should return data in transformed format', function() {
            httpMock.post.returnValue = _.clone(returnValueAfterSave);
            service.saveChanges(instrType, function(searchData) {
                expect(searchData.characteristics instanceof ArrayExt).toBe(true);
                expect(searchData.instructions instanceof ArrayExt).toBe(true);

                expect(_.first(searchData.characteristics.items) instanceof ObjectExt).toBe(true);
                expect(_.first(searchData.instructions.items) instanceof ObjectExt).toBe(true);
            });
        });

        it('should maintain saved items for updated instructions', function() {
            instrType.instructions.updated = [{
                id: 1,
                description: 'abcd',
                characteristics: []
            }];
            httpMock.post.returnValue = _.clone(returnValueAfterSave);
            service.saveChanges(instrType, function() {});

            expect(service.saved.instructions.items.length).toBe(1);
        });

        it('should maintain saved items for updated characteristic', function() {
            instrType.characteristics.updated = [{
                id: 1,
                description: 'abcd',
                characteristics: []
            }];
            httpMock.post.returnValue = _.clone(returnValueAfterSave);
            service.saveChanges(instrType, function() {});

            expect(service.saved.characteristics.items.length).toBe(1);
        });

        it('should maintain saved items for updated assigned characteristic', function() {
            instrType.instructions.updated = [{
                id: 1,
                description: 'abcd',
                characteristics: [{
                    id: 4
                }]
            }];
            httpMock.post.returnValue = _.clone(returnValueAfterSave);
            service.saveChanges(instrType, function() {});

            expect(service.saved.instructions.items.length).toBe(1);
            expect(_.first(service.saved.instructions.items).characteristics.items.length).toBe(1);
        });

        it('should maintain saved items for added instructions', function() {
            instrType.instructions.added = [{
                id: 'temp1',
                description: 'abcd',
                characteristics: []
            }];

            var value = _.clone(returnValueAfterSave);
            value.data.instructions = [{
                id: 1,
                description: 'abcd',
                correlationId: 'temp1'
            }];
            httpMock.post.returnValue = value;
            service.saveChanges(instrType, function(data) {
                expect(_.first(data.instructions.items).obj.id).toBe(1);
                expect(service.saved.instructions.items.length).toBe(1);
                expect(_.first(service.saved.instructions.items).obj.id).toBe(1);
            });
        });

        it('should maintain saved items for added characteristic', function() {
            instrType.characteristics.added = [{
                id: 'temp1',
                description: 'abcd',
                characteristics: []
            }];

            var value = _.clone(returnValueAfterSave);
            value.data.characteristics = [{
                id: 1,
                description: 'abcd',
                correlationId: 'temp1'
            }];

            httpMock.post.returnValue = value;

            service.saveChanges(instrType, function(data) {
                expect(_.first(data.characteristics.items).obj.id).toBe(1);
            });
            expect(service.saved.characteristics.items.length).toBe(1);
            expect(_.first(service.saved.characteristics.items).obj.id).toBe(1);
        });
    });
});
