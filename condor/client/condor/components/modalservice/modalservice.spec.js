describe('Service inprotech.components.modalService', function() {
    'use strict';

    beforeEach(module('inprotech.components.modal'));

    var service, uibModal, scope, transitions, modalInstance;

    beforeEach(function() {
        module(function() {
            modalInstance = test.mock('ModalInstance', 'ModalInstanceMock');
            
            uibModal = {
                open: jasmine.createSpy().and.returnValue(modalInstance)
            };
            
            test.mock('$uibModal', uibModal);
            transitions = test.mock('$transitions', 'transitionsMock');
            test.mock('hotkeyService');
        });

        inject(function(modalService, $rootScope) {
            service = modalService;
            scope = $rootScope.$new();
        });
    });

    it('should initialise the service', function() {
        expect(service).toBeDefined();
    });

    it('should register a modal', function() {
        var registry = service.getRegistry();

        var returnValue = service.register('Modal', 'ModalController', 'template.html');

        expect(returnValue).toBe(true);
        expect(registry.Modal).toBeDefined();
        expect(registry.Modal.controller).toBe('ModalController');
        expect(registry.Modal.templateUrl).toBe('template.html');
        expect(registry.Modal.isOpen).toBe(false);
        expect(registry.Modal.instance).toBeNull();
        expect(registry.Modal.options).toEqual({
            backdrop: 'static',
            backdropClass: 'centered'
        });
    });

    it('should not register a modal twice', function() {
        var registry = service.getRegistry();

        var returnValue1 = service.register('Modal', 'ModalController', 'template.html');
        var returnValue2 = service.register('Modal', 'ModalController2', 'template2.html');

        expect(registry.Modal).toBeDefined();
        expect(registry.Modal.controller).toBe('ModalController');
        expect(registry.Modal.templateUrl).toBe('template.html');
        expect(registry.Modal.controller).not.toBe('ModalController2');
        expect(registry.Modal.templateUrl).not.toBe('template2.html');
        expect(returnValue1).toBe(true);
        expect(returnValue2).toBe(false);
    });

    it('should not open a modal twice', function() {
        service.register('Modal', 'ModalController', 'template.html');

        service.open('Modal', scope);

        expect(uibModal.open).toHaveBeenCalled();
        expect(service.isOpen('Modal')).toBe(true);

        uibModal.open.calls.reset();

        service.open('Modal', scope);
        expect(uibModal.open).not.toHaveBeenCalled();
        expect(service.isOpen('Modal')).toBe(true);
    });

    it('should open modals of different types', function() {
        service.register('Modal', 'ModalController', 'template.html');

        service.open('Modal', scope);

        expect(uibModal.open).toHaveBeenCalled();

        service.open('Modal.type', scope);
        expect(uibModal.open).toHaveBeenCalled();

        service.open('Modal.type_maintainable', scope);
        expect(uibModal.open).toHaveBeenCalled();

        expect(service.isOpen('Modal')).toBe(true);
        expect(service.isOpen('Modal.type')).toBe(true);
        expect(service.isOpen('Modal.type_maintainable')).toBe(true);
        
    });

    it('should append anchor tag to work around tabbing into background', function() {
        service.register('Modal', 'ModalController', 'template.html');
        var jqSpy = spyOn($.fn, 'append');

        modalInstance.rendered.then.and.callThrough(); // make the rendered then call through
        
        service.open('Modal', scope);

        expect(jqSpy).toHaveBeenCalled();
        expect(jqSpy.calls.mostRecent().args[0]).toMatch(/a.*href=\"\"/);
    });

    it('should open a modal', function() {
        service.register('Modal', 'ModalController', 'template.html');

        service.open('Modal', scope);

        expect(uibModal.open).toHaveBeenCalled();
        expect(service.isOpen('Modal')).toBe(true);
    });

    it('should open a modal with named parameters', function() {
        service.register('Modal', 'ModalController', 'template.html');

        service.open({
            id: 'Modal',
            scope: scope,
            templateUrl: 'custom.html',
            controllerAs: 'vm',
            options: {
                dataId: 213
            }
        });

        expect(uibModal.open).toHaveBeenCalledWith(jasmine.objectContaining({
            controller: 'ModalController',
            templateUrl: 'custom.html',
            scope: scope,
            controllerAs: 'vm',
            backdrop: 'static'
        }));
        expect(service.isOpen('Modal')).toBe(true);
    });

    it('should not call named parameters if the only parameter is not a object', function() {
        service.register('Modal', 'ModalController', 'template.html');

        service.open('Modal');

        expect(uibModal.open).toHaveBeenCalledWith(jasmine.objectContaining({
            controller: 'ModalController',
            templateUrl: 'template.html'
        }));

        expect(service.isOpen('Modal')).toBe(true);
    });

    it('should close a modal', function() {
        service.register('Modal', 'ModalController', 'template.html');

        service.open('Modal', scope);
        var instance = service.getInstance('Modal');

        service.close('Modal');

        expect(instance.close).toHaveBeenCalled();
    });

    it('can open a dialog if no other modal is open', function() {
        expect(service.canOpen()).toBe(true);

        service.register('Modal', 'ModalController', 'template.html');
        service.open('Modal', scope);

        expect(service.canOpen()).toBe(false);
    });

    it('can open a dialog if no other modal is open and withModal is open', function() {
        expect(service.canOpen('Modal')).toBe(false);

        service.register('Modal', 'ModalController', 'template.html');
        service.open('Modal', scope);

        expect(service.canOpen('Modal')).toBe(true);
    });

    it('leaving page should dismiss modal', function() {
        service.register('Modal', 'ModalController', 'template.html');
        service.open('Modal', scope);


        expect(transitions.onStart).toHaveBeenCalled();
        spyOn(service, 'cancel');
        
        var callback = transitions.onStart.calls.first().args[1];
        callback();

        expect(service.cancel).toHaveBeenCalledWith('Modal');
        expect(transitions.onStartUnbindSpy).toHaveBeenCalled();
    });
});
