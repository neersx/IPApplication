describe('inprotech.core.moment', function() {
    'use strict';
    /*eslint-disable */
    var _rootScope, _moment, _momentFilter, defaultMoment;

    beforeEach(module('inprotech.core'));
    beforeEach(inject(function($rootScope, $filter) {

        defaultMoment = window.moment;

        window.moment = _moment = function() {
            return _moment;
        };
        _moment.locale = function() {
            return _moment;
        };
        _moment.format = function() {
            return _moment;
        };

        _rootScope = $rootScope;
        _rootScope.appContext = {};
        _rootScope.appContext.user = {
            preferences: {
                culture: null,
                dateFormat: null
            }
        };
        _rootScope.appContext.userAgent = {
            languages: []
        };

        _momentFilter = $filter('moment', {
            $rootScope: _rootScope
        });
    }));
    
    afterEach(function() {
        window.moment = defaultMoment;
    });
    /*eslint-enable */
    function setCulture(culture) {
        _rootScope.appContext.user.preferences.culture = culture;
    }

    function setDateFormat(dateFormat) {
        _rootScope.appContext.user.preferences.dateFormat = dateFormat;
    }

    function setBrowserLanguage(language) {
        _rootScope.appContext.userAgent.languages[0] = language;
    }

    describe('input', function() {
        it('should return empty if there is no input', function() {
            var r = _momentFilter();
            expect(r).toBe('');
        });
    });

    describe('user not logged in', function() {
        beforeEach(function() {
            _rootScope.appContext.user = null;
        });

        it('should use browser default culture', function() {
            var method = spyOn(_moment, 'locale');

            _momentFilter('2000-01-02');
            expect(method).not.toHaveBeenCalled();
        });

        it('should use short date format', function() {
            var method = spyOn(_moment, 'format');

            _momentFilter('2000-01-02');
            expect(method).toHaveBeenCalledWith('ll');
        });
    });

    describe('culture', function() {
        it('should use preferred culture', function() {
            setCulture('en-AU');
            var method = spyOn(_moment, 'locale').and.callThrough();

            _momentFilter('2000-01-02');
            expect(method).toHaveBeenCalledWith('en-AU');
        });

        it('should use browser default culture if not defined in preferences', function() {
            setCulture('');
            var method = spyOn(_moment, 'locale');

            _momentFilter('2000-01-02');
            expect(method).not.toHaveBeenCalled();
        });

        it('should use browser\'s language if culture is not specified', function() {
            setCulture('');
            setBrowserLanguage('en-AU');
            var method = spyOn(_moment, 'locale').and.callThrough();

            _momentFilter('2000-01-02');
            expect(method).toHaveBeenCalledWith('en-AU');
        });
    });

    describe('no specific date format', function() {
        it('should use short date format', function() {
            setDateFormat('d');
            var method = spyOn(_moment, 'format');

            _momentFilter('2000-01-02');
            expect(method).toHaveBeenCalledWith('ll');
        });
    });

    describe('specific date format', function() {
        it('should convert to momentjs format', function() {
            setDateFormat('dd-MMM-yyyy');
            var method = spyOn(_moment, 'format');

            _momentFilter('2000-01-02');
            expect(method).toHaveBeenCalledWith('DD-MMM-YYYY');
        });
    });
});