namespace inprotech.accounting.vat {
    export class HmrcHeadersBuilderServiceMock implements IHmrcHeadersBuilderService {
        appContext: any;
        headerPairs: {};
        constructor() {
            spyOn(this, 'initialise').and.callThrough();
            spyOn(this, 'getClientPublicIp').and.callThrough();
            spyOn(this, 'getClientLocalIp').and.callThrough();
            spyOn(this, 'getclientBrowserDoNoTrack').and.callThrough();
            spyOn(this, 'getCurrentTimeZone').and.callThrough();
            spyOn(this, 'getClientScreens').and.callThrough();
            spyOn(this, 'getClientWindowSize').and.callThrough();
            spyOn(this, 'calculateCurrentTimeZone').and.callThrough();
            spyOn(this, 'getclientDeviceId').and.callThrough();
            spyOn(this, 'resolve').and.callThrough();
        }

        initialise(): ng.IPromise<any> { return };
        getClientPublicIp(): ng.IPromise<string> { return };
        getClientLocalIp(): Promise<any> { return };
        getclientBrowserDoNoTrack(): string { return };
        getCurrentTimeZone(): string { return };
        getClientScreens(): string { return };
        getClientWindowSize(): string { return };
        calculateCurrentTimeZone(): string { return };
        getclientDeviceId(): string { return };
        resolve(): ng.IPromise<any> { return };
    }
    angular.module('inprotech.mocks').service('HmrcHeadersBuilderServiceMock', HmrcHeadersBuilderServiceMock);
}