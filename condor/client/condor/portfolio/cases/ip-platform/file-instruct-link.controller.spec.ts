namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.fileInstructLinkController', () => {
        'use strict';

        let c: FileInstructLinkController, notificationService: any, httpMock: any, windowMock = {
            open: (url: string, name: string) => {}
        };
        let controller: (dependencies: any) => FileInstructLinkController;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
                notificationService = $injector.get('notificationServiceMock');
                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject(() => {
            controller = function(options: any) {
                windowMock = {
                    open: jasmine.createSpy('')
                };

                let ct = new FileInstructLinkController(httpMock, notificationService, windowMock);
                ct.caseKey = options.caseKey;
                ct.isFiled = options.isFiled;
                ct.canAccess = options.canAccess;
                ct.$onInit();
                return ct;
            };
        }));

        describe('initialise', () => {
            describe('for filed case', () => {
                it('should show icon only if access not available', () => {
                    c = controller({
                        caseKey: 456,
                        isFiled: true,
                        canAccess: false
                    });
                    expect(c.showIconOnly).toBe(true);
                    expect(c.showLink).toBe(false);
                });
                it('should show icon only if access available', () => {
                    c = controller({
                        caseKey: 456,
                        isFiled: true,
                        canAccess: true
                    });
                    expect(c.showIconOnly).toBe(false);
                    expect(c.showLink).toBe(true);
                });
            });
            describe('for non-filed case', () => {
                it('should set show icon only when without access', () => {
                    c = controller({
                        caseKey: 456,
                        isFiled: false,
                        canAccess: false
                    });
                    expect(c.showIconOnly).toBe(false);
                    expect(c.showLink).toBe(false);
                });
            });
        });

        describe('link to FILE', () => {
            it('should open a window with the url returned', () => {
                httpMock.put.returnValue = {
                    result: {
                        progressUri: 'https://ip-platform.com/file/instruct/someguid'
                    }
                };

                c = controller({
                    caseKey: 456,
                    isFiled: true,
                    canAccess: true
                });

                c.link();

                expect(windowMock.open).toHaveBeenCalledWith('https://ip-platform.com/file/instruct/someguid', '_blank');
            });
        });

        describe('unable to link to FILE', () => {
            it('should notify the user of the error', () => {
                httpMock.put.returnValue = {
                    result: {
                        errorDescription: 'Unable to open case in FILE.'
                    }
                };

                c = controller({
                    caseKey: 456,
                    isFiled: true,
                    canAccess: true
                });

                c.link();

                expect(notificationService.alert).toHaveBeenCalledWith({
                    title: 'modal.unableToComplete',
                    message: 'Unable to open case in FILE.'
                });
            });
        })
    });
}