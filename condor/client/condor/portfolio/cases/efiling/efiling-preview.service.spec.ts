namespace inprotech.portfolio.cases {
    'use strict';

    describe('inprotech.portfolio.cases.eFilingPreview', () => {
        let service: (navigator?: any) => IEfilingPreview, window: ng.IWindowService;
        let response: any;
        let s: IEfilingPreview;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(inject(($window: ng.IWindowService) => {
            window = $window;
            service = () => {
                return new EfilingPreview(window);
            };
            spyOn(window, 'open').and.callThrough();
            spyOn(window.document, 'createElement').and.callThrough();

        }));

        describe('preview function', () => {
            it('uses anchor for zip files', () => {
                response = {
                    headers: () => {
                        let r = {
                            ['content-type']: 'abc-type',
                            ['x-filetype']: 'zip'
                        };
                        return r;
                    },
                    data: '¯_(ツ)_/¯'
                };
                s = service();
                s.preview(response);

                expect(window.document.createElement).toHaveBeenCalledWith('a');
            });
            it('uses anchor for mpx files', () => {
                response = {
                    headers: () => {
                        let r = {
                            ['content-type']: 'abc-type',
                            ['x-filetype']: 'MPX'
                        };
                        return r;
                    },
                    data: '¯_(ツ)_/¯'
                };
                s = service();
                s.preview(response);

                expect(window.document.createElement).toHaveBeenCalledWith('a');
            });
            it('tells IE to save or open the file', () => {
                response = {
                    headers: () => {
                        let r = {
                            ['content-type']: 'abc-type',
                            ['x-filetype']: 'zip'
                        };
                        return r;
                    },
                    data: '¯_(ツ)_/¯'
                };
                let windowMocked = angular.extend({}, window);
                windowMocked = angular.extend(windowMocked, { navigator: { msSaveOrOpenBlob: () => { } } }, { URL: window.URL });

                s = new EfilingPreview(windowMocked);
                spyOn(windowMocked.navigator, 'msSaveOrOpenBlob');
                s.preview(response);

                expect(windowMocked.document.createElement).not.toHaveBeenCalled();
                expect(windowMocked.navigator.msSaveOrOpenBlob).toHaveBeenCalled();
                expect(windowMocked.open).not.toHaveBeenCalled();
            });
            it('previews the file in another tab', () => {
                response = {
                    headers: () => {
                        let r = {
                            ['content-type']: 'xyz-type',
                            ['x-filetype']: 'XYZ'
                        };
                        return r;
                    },
                    data: '¯_(ツ)_/¯'
                };
                s = service();
                s.preview(response);

                expect(window.document.createElement).not.toHaveBeenCalled();
                expect(window.open).toHaveBeenCalled();
            });
        });
    });
}