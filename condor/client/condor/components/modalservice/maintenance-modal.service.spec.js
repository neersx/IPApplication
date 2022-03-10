describe('maintenanceModalService', function() {
    var service;

    var scope, modalInstance, addItemFunc;
    beforeEach(function() {
        module('inprotech.components.modal')
        module(function() {
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
        });

        inject(function(maintenanceModalService) {
            scope = {
                $emit: jasmine.createSpy()
            };
            addItemFunc = jasmine.createSpy();
            service = maintenanceModalService(scope, modalInstance, addItemFunc);
        });
    });

    describe('apply changes', function() {
        var options, data;
        beforeEach(function() {
            options = {
                dataItem: {
                    name: 'abc',
                    someField: {
                        value: 123
                    }
                }
            };

            data = {
                someField: {
                    value: 456
                }
            };
        });

        describe('edit mode', function() {
            it('merges data and closes', function() {
                service.applyChanges(data, options, true, null, false);

                expect(options.dataItem).toEqual(jasmine.objectContaining({
                    name: 'abc',
                    someField: {
                        value: 456
                    }
                }));
                expect(modalInstance.close).toHaveBeenCalled();
            });

            it('merges array data', function() {
                
                options.dataItem.nameTypes = [{id: 'a'}, {id: 'c'}, {id: 'd'}];
                data.nameTypes = [{id: 'a'}, {id: 'b'}];

                service.applyChanges(data, options, true, null, false);

                expect(options.dataItem.nameTypes.length).toEqual(2);
                expect(options.dataItem.nameTypes[0].id).toEqual('a');
                expect(options.dataItem.nameTypes[1].id).toEqual('b');
                expect(options.dataItem.nameTypes[2]).toBeUndefined();
            });

            it('keeps open if keepOpen flag true', function(){
                service.applyChanges(data, options, true, null, true);
                
                expect(modalInstance.close).not.toHaveBeenCalled();
            });
        });

        describe('addAnother', function() {
            it('calls addItem callback and emits modalChangeView', function() {
                service.applyChanges(data, options, false, true);

                expect(addItemFunc).toHaveBeenCalledWith(data);
                expect(scope.$emit).toHaveBeenCalledWith('modalChangeView', jasmine.objectContaining(_.extend(options, {
                    isAddAnother: true
                })));
                expect(modalInstance.close).not.toHaveBeenCalled();
            });
        });

        describe('add', function() {
            it('closes modal with data', function() {
                service.applyChanges(data, options, false, false);

                expect(modalInstance.close).toHaveBeenCalledWith(data);
            });
        });
    });
});