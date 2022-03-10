describe('blockUiInterceptor', function() {
    'use strict';

    beforeEach(module('inprotech.http'));

    var interceptor, uibModalMock;

    beforeEach(module(function($provide) {
        uibModalMock = {
            open: jasmine.createSpy()
        };

        $provide.value("$uibModal", uibModalMock);

        // Workaround : @angular-devkit/build-angular` breaks Jasmine's mock clock 
        // https://github.com/angular/angular-cli/issues/11626 
        jasmine.clock().uninstall();
        
        jasmine.clock().install();
    }));

    beforeEach(inject(function(blockUiInterceptor) {
        interceptor = blockUiInterceptor;
    }));

    afterEach(function() {
        jasmine.clock().uninstall();
    });

    it('can get an instance', function() {
        expect(interceptor).toBeDefined();
    });

    it('opens the blocking modal on put, post and delete', function() {
        var expectedParam = {
            templateUrl: 'condor/http/block.html',
            windowClass: 'block-modal-window',
            backdrop: 'static',
            size: 's'
        };

        interceptor.request({
            method: "PUT"
        });
        jasmine.clock().tick(300);
        expect(uibModalMock.open).toHaveBeenCalledWith(expectedParam);

        uibModalMock.open.calls.reset();
        interceptor.request({
            method: "POST"
        });
        jasmine.clock().tick(300);
        expect(uibModalMock.open).toHaveBeenCalledWith(expectedParam);
        
        uibModalMock.open.calls.reset();
        interceptor.request({
            method: "DELETE"
        });
        jasmine.clock().tick(300);
        expect(uibModalMock.open).toHaveBeenCalledWith(expectedParam);
    });

    it('does not open the blocking modal for other Api calls', function() {
        interceptor.request({
            method: "GET"
        });
        expect(uibModalMock.open).not.toHaveBeenCalled();
    });

    describe('closing blocking modal', function() {
        var closeSpy;
        beforeEach(function() {
            closeSpy = jasmine.createSpy();
            uibModalMock.open.and.returnValue({
                close: closeSpy
            });
            interceptor.request({
                method: "PUT"
            });
            jasmine.clock().tick(300);
        });

        it('closes blocking modal after response received', function() {
            interceptor.response({
                config: {
                    method: "PUT"
                }
            });
            jasmine.clock().tick(100);
            expect(closeSpy).toHaveBeenCalled();
        });

        it('closes blocking modal after request error received', function() {
            interceptor.requestError({
                config: {
                    method: "PUT"
                }
            });
            jasmine.clock().tick(100);
            expect(closeSpy).toHaveBeenCalled();
        });

        it('closes blocking modal after response error received', function() {
            interceptor.responseError({
                config: {
                    method: "PUT"
                }
            });
            jasmine.clock().tick(100);
            expect(closeSpy).toHaveBeenCalled();
        });
    });

    describe('closing blocking modal race condition', function() {
        it('does not open a modal if a response error occurred within the timeout', function() {
            interceptor.request({
                method: "PUT"
            });
            interceptor.responseError({
                config: {
                    method: "PUT"
                }
            });
            jasmine.clock().tick(300);
            expect(uibModalMock.open).not.toHaveBeenCalled();
        });

        it('does not open a modal if a response success occurred within the timeout', function() {
            interceptor.request({
                method: "PUT"
            });
            interceptor.response({
                config: {
                    method: "PUT"
                }
            });
            jasmine.clock().tick(300);
            expect(uibModalMock.open).not.toHaveBeenCalled();
        });
    });
});
