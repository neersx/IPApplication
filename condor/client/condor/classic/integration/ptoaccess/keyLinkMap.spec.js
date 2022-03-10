describe('keyLinkMap', function() {
    'use strict';

    var _keyLinkMap;

    beforeEach(module(function($provide) {
        var $injector = angular.injector(['inprotech.mocks']);
        $provide.value('modalService', $injector.get('modalServiceMock'));
    }));

    beforeEach(module('inprotech.classic'));

    beforeEach(module('Inprotech.Integration.PtoAccess'));

    beforeEach(inject(function(keyLinkMap) {
        _keyLinkMap = keyLinkMap;
    }));

    describe('get link method', function() {
        it('should return link for associated key', function() {
            var link = _keyLinkMap.getLinkFor('epo-missing-keys', 'DataSource');
            expect(link).not.toBeNull();
            expect(link.text).toBe('ConfigureEPOSetting');
            expect(link.link).toBe('../../#/pto-settings/epo');
        });

        it('should not return key', function() {
            var link = _keyLinkMap.getLinkFor('some-other-key', 'DataSource');
            expect(link).not.toBeDefined();

            link = _keyLinkMap.getLinkFor('epo-missing-keys', 'Some other control');
            expect(link).not.toBeDefined();
        });
    });
});