describe('InprotechSignInRedirect.redirectController', function() {
    'use strict';

    var _controller, _location, _window, _localStorage;
    var authModes = {
        forms: 1,
        windows: 2,
        sso: 3
    };

    var getObject = function() {
        var value = window.localStorage['signin'];
        if (value === 'null') {
            value = null;
        }
        return value ? JSON.parse(value) : {};
    };
    var setObject = function(values) {
        window.localStorage['signin'] = JSON.stringify(values);
    };

    var setItem = function(key, value) {
        var signinValue = getObject();
        signinValue[key] = value;
        setObject(signinValue);
    };
    var getItem = function(key) {
        return getObject()[key];
    }

    beforeEach(module('inprotechSigninRedirect'));

    beforeEach(inject(function($controller, $location) {
        _location = $location;
        _window = {};

        spyOn(_location, 'path');

        _controller = function() {
            return $controller('redirectController', {
                '$window': _window
            });
        };
    }));

    it('should set auth mode to sso if logged in using sso', function() {
        setItem('authModeTemp', authModes.sso);

        _controller();

        expect(getItem('authMode')).toBe(authModes.sso);
        expect(getItem('authModeTemp')).toBe(null);
        expect(_window.location.indexOf('/#/home') !== -1).toBe(true);
    });

    it('should not change auth mode if not logged in as sso', function() {
        setItem('authMode', authModes.windows);
        setItem('authModeTemp', null);

        _controller();

        expect(getItem('authMode')).toBe(authModes.windows);
        expect(getItem('authModeTemp')).toBe(null);
        expect(_window.location.indexOf('/#/home') !== -1).toBe(true);
    });

    it('should redirect user to home when no goto value provided', function() {
        _controller();

        expect(_window.location.indexOf('/#/home') !== -1).toBe(true);
    });

    it('should redirect user to goto value', function() {
        _location.search({
            'goto': 'abc'
        });

        setItem('authMode', authModes.windows);
        setItem('authModeTemp', null);

        _controller();

        expect(getItem('authMode')).toBe(authModes.windows);
        expect(getItem('authModeTemp')).toBe(null);
        expect(_window.location.indexOf('/#/home') !== -1).toBe(false);
        expect(_window.location.indexOf('abc') !== -1).toBe(true);
    });
});