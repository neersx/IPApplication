describe('inprotech.configuration.general.ptosettings.epo.EpoSettingsService', () => {
    'use strict';

    let service: IEpoSettingsService, httpMock: any;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.ptosettings');
        angular.mock.module(($provide) => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject((EpoSettingsService: IEpoSettingsService) => {
        service = EpoSettingsService;
    }));

    describe('save call', () => {
        it('should call server to save passed values', () => {
            httpMock.post.returnValue = {
                result: { status: 'success' }
            }

            let keys = new EpoSettingModel('sansa', 'arya');
            let result = service.save(keys);
            expect(result).toBeTruthy();

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/ptosettings/epo', JSON.stringify(keys));
        });

        it('save should return false, if server returns error', () => {
            httpMock.post.returnValue = {
                result: { status: 'error' }
            }

            let keys = new EpoSettingModel('sansa', 'arya');
            let result = service.save(keys);
            expect(result).toBeFalsy();
        });
    });


    describe('test call', () => {
        it('should call server to test passed values', () => {
            httpMock.put.returnValue = {
                result: { status: 'success' }
            }

            let keys = new EpoSettingModel('sansa', 'arya');
            let result = service.test(keys);
            expect(result).toBeTruthy();

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/ptosettings/epo', JSON.stringify(keys));
        });
    });

    it('test should return false, if server returns error', () => {
        httpMock.put.returnValue = {
            result: { status: 'error' }
        };
        let keys = new EpoSettingModel('sansa', 'arya');
        let result = service.test(keys);
        expect(result).toBeFalsy();
    });
})
