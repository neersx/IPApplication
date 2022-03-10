namespace inprotech.accounting.vat {
    'use strict';

    declare var test: any;

    describe('inprotech.accounting.vat.hmrcheader.builder.service', () => {
        let service: () => IHmrcHeadersBuilderService, http, promiseMock, window, store;

        beforeEach(() => {
            angular.mock.module(() => {
                http = test.mock('$http', 'httpMock');
                promiseMock = test.mock('promise', 'promiseMock');
            });
            angular.mock.module('inprotech.mocks');
        });

        beforeEach(inject(($window: ng.IWindowService, $sce: ng.ISCEService, $q: ng.IQService) => {
            window = $window;

            service = () => {
                return new HmrcHeadersBuilderService(http, window, $sce, store, $q);
            };
        }));

        it('correctly calculates current timezone', () => {
            let s = service();
            let result = s.calculateCurrentTimeZone();

            expect(result).toContain('UTC');
        });

        it('correctly initialises service', () => {
            let s = service();
            s.getClientPublicIp = promiseMock.createSpy();
            s.initialise('testDeviceId');

            expect(s.getClientPublicIp).toHaveBeenCalledTimes(1);
        });

        it('calls the right functions when resolving', () => {
            let s = service();
            spyOn(s, 'getCurrentTimeZone').and.returnValue('UTC +10:00');
            spyOn(s, 'getClientScreens').and.returnValue('1200X800');
            spyOn(s, 'getClientWindowSize').and.returnValue('1400X1800');
            spyOn(s, 'getclientDeviceId').and.returnValue('fgdfgdfg');
            spyOn(s, 'getclientBrowserDoNoTrack').and.returnValue('true');
            let resolve = s.resolve();

            expect(s.getCurrentTimeZone).toHaveBeenCalledTimes(1);
            expect(s.getClientScreens).toHaveBeenCalledTimes(1);
            expect(s.getClientWindowSize).toHaveBeenCalledTimes(1);
            expect(s.getclientDeviceId).toHaveBeenCalledTimes(1);
            expect(s.getclientBrowserDoNoTrack).toHaveBeenCalledTimes(1);
            expect(resolve['x-inprotech-current-timezone']).toEqual('UTC +10:00');
            expect(resolve['x-inprotech-client-screens']).toEqual('1200X800');
            expect(resolve['x-inprotech-client-window-size']).toEqual('1400X1800');
            expect(resolve['x-inprotech-client-device-id']).toEqual('fgdfgdfg');
            expect(resolve['x-inprotech-client-browser-do-not-track']).toEqual('true');
        });

    });
}