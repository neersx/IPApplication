namespace inprotech.core {
    'use strict';

    describe('feature detection', function () {

        let service: (window?) => FeatureDetection, getwindow: (userAgent?: string) => void, rootScope;
        getwindow = function (userAgent) {
            return {
                navigator: {
                    userAgent: userAgent || 'MSIE '
                }
            };
        }
        beforeEach(function () {
            angular.mock.module('inprotech.core');


            let $injector: ng.auto.IInjectorService = angular.injector(['ng', 'inprotech.mocks.core']);

            rootScope = $injector.get('$rootScope');
            service = (window) => new FeatureDetection(rootScope, window || getwindow());
        });

        describe('check Browser', function () {
            it('checks for ie', function () {
                let r = service().isIe();
                expect(r).toBeTruthy();

                r = service(getwindow('Trident/')).isIe();
                expect(r).toBeTruthy();
            });

            it('Returns false for non ie', function () {
                let r = service(getwindow('Chrome ')).isIe();
                expect(r).toBeFalsy();

                r = service(getwindow('Firefox ')).isIe();
                expect(r).toBeFalsy();
            });

        });

        describe('check inprotech version', function () {
            let setInprotechVersion: (v?: string) => void = (v) => {
                rootScope.appContext = {
                    systemInfo: {
                        inprotechVersion: v || 'v13'
                    }
                };
            }
            it('checks for Release13', function () {
                setInprotechVersion();
                let s = service();
                expect(s.hasRelease13()).toBeTruthy();

                setInprotechVersion('v13.0.5');
                expect(s.hasRelease13()).toBeTruthy();

                setInprotechVersion('v14.0.5');
                expect(s.hasRelease13()).toBeTruthy();

                setInprotechVersion('v 15.0.5');
                expect(s.hasRelease13()).toBeTruthy();
            });

            it('checks if not Release13', function () {
                setInprotechVersion('abcd');
                let s = service();
                expect(s.hasRelease13()).toBeFalsy();

                setInprotechVersion('v1.3.5');
                expect(s.hasRelease13()).toBeFalsy();

                setInprotechVersion('v4.0.5');
                expect(s.hasRelease13()).toBeFalsy();

                setInprotechVersion('v 10.15.5');
                expect(s.hasRelease13()).toBeFalsy();
            });
        });

        it('gets the url', function () {
            let s = service();
            let url = window.location;
            let baseUrl = url.protocol + '//' + url.host;
            expect(s.getAbsoluteUrl('/abc')).toEqual(baseUrl + '/abc');
            expect(s.getAbsoluteUrl('../abc')).toEqual(baseUrl + '/abc');
        });

    });

}