describe('inprotech.components.form.dateService', function() {
    'use strict';

    function getDateParserService() {
        return {
            setParserFormat: jasmine.createSpy()
        };
    }

    function build(culture, dateFormat) {
        return {
            appContext: {
                user: {
                    preferences: {
                        culture: culture || 'en',
                        dateFormat: dateFormat || 'dd-MMM-yyyy'
                    }
                }
            }
        }
    }

    beforeEach(module('inprotech.components.form'));

    describe('return information required for date picker', function() {

        var service, dateParserService;
        var scope = build('en-AU', 'dd-MMM-yyyy');

        beforeEach(module(function($provide) {
            $provide.value('$rootScope', scope);

            dateParserService = getDateParserService();
            $provide.value('dateParserService', dateParserService);
        }));

        beforeEach(inject(function(dateService) {
            service = dateService;
        }));

        it('should pick culture from user preferences', function() {
            expect(service.culture).toEqual('en-AU');
        });

        it('should pick date format from user preferences', function() {
            expect(service.dateFormat).toEqual('dd-MMM-yyyy');
        });

        it('should allow long date format to be parsed', function() {
            expect(service.getParseFormats()).toContain('longDate');
        });

        it('should allow iso 8601 format to be parsed', function() {
            expect(service.getParseFormats()).toContain('yyyy-MM-dd');
        });
    });

    describe('allows relaxed parse formats from Date Style 1', function() {
        var service, dateParserService;
        var scope = build('en-AU', 'dd-MMM-yyyy');

        beforeEach(module(function($provide) {
            $provide.value('$rootScope', scope);
            dateParserService = getDateParserService();
            $provide.value('dateParserService', dateParserService);
        }));

        beforeEach(inject(function(dateService) {
            service = dateService;
        }));

        it('should return all formats substituting different delimiters', function() {
            var parseFormats = service.getParseFormats();
            expect(parseFormats).toContain('dd-MMM-yyyy');
            expect(parseFormats).toContain('dd MMM yyyy');
            expect(parseFormats).toContain('dd/MMM/yyyy');
            expect(parseFormats).toContain('dd.MMM.yyyy');
        });

        it('should call dateParserService to set parsing format', function() {
            service.getParseFormats();

            expect(dateParserService.setParserFormat).toHaveBeenCalledWith('dd-MMM-yyyy', '-');
            expect(dateParserService.setParserFormat).toHaveBeenCalledWith('dd MMM yyyy', ' ');
            expect(dateParserService.setParserFormat).toHaveBeenCalledWith('dd/MMM/yyyy', '/');
            expect(dateParserService.setParserFormat).toHaveBeenCalledWith('dd.MMM.yyyy', '.');
        });

        it('should return parseFormats with numeric months and double digit years', function() {
            var parseFormats = service.getParseFormats();
            expect(parseFormats).toContain('d!-M!-yyyy');
            expect(parseFormats).toContain('d! M! yyyy');
            expect(parseFormats).toContain('d!/M!/yyyy');
            expect(parseFormats).toContain('d!.M!.yyyy');
            expect(parseFormats).toContain('d!-M!-yy');
            expect(parseFormats).toContain('d! M! yy');
            expect(parseFormats).toContain('d!/M!/yy');
            expect(parseFormats).toContain('d!.M!.yy');
        });
    })

    describe('allows relaxed parse formats from Date Style 2', function() {
        var service, dateParserService;
        var scope = build('en-AU', 'MMM-dd-yyyy');

        beforeEach(module(function($provide) {
            $provide.value('$rootScope', scope);
            dateParserService = getDateParserService();
            $provide.value('dateParserService', dateParserService);
        }));

        beforeEach(inject(function(dateService) {
            service = dateService;
        }));

        it('should return all formats substituting different delimiters', function() {
            var parseFormats = service.getParseFormats();
            expect(parseFormats).toContain('MMM-dd-yyyy');
            expect(parseFormats).toContain('MMM dd yyyy');
            expect(parseFormats).toContain('MMM/dd/yyyy');
            expect(parseFormats).toContain('MMM.dd.yyyy');
        });

        it('should return parseFormats with numeric months and double digit years', function() {
            var parseFormats = service.getParseFormats();
            expect(parseFormats).toContain('M!-d!-yyyy');
            expect(parseFormats).toContain('M! d! yyyy');
            expect(parseFormats).toContain('M!/d!/yyyy');
            expect(parseFormats).toContain('M!.d!.yyyy');
            expect(parseFormats).toContain('M!-d!-yy');
            expect(parseFormats).toContain('M! d! yy');
            expect(parseFormats).toContain('M!/d!/yy');
            expect(parseFormats).toContain('M!.d!.yy');
        });
    })

    describe('allows relaxed parse formats from Date Style 3', function() {
        var service, dateParserService;
        var scope = build('en-AU', 'yyyy-MMM-dd');

        beforeEach(module(function($provide) {
            $provide.value('$rootScope', scope);
            dateParserService = getDateParserService();
            $provide.value('dateParserService', dateParserService);
        }));

        beforeEach(inject(function(dateService) {
            service = dateService;
        }));

        it('should return all formats substituting different delimiters', function() {
            var parseFormats = service.getParseFormats();
            expect(parseFormats).toContain('yyyy-MMM-dd');
            expect(parseFormats).toContain('yyyy MMM dd');
            expect(parseFormats).toContain('yyyy/MMM/dd');
            expect(parseFormats).toContain('yyyy.MMM.dd');
        });

        it('should call dateParserService to set parsing format', function() {
            service.getParseFormats();

            expect(dateParserService.setParserFormat).toHaveBeenCalled();
        });

        it('should return parseFormats with numeric months and double digit years', function() {
            var parseFormats = service.getParseFormats();
            expect(parseFormats).toContain('yyyy-M!-d!');
            expect(parseFormats).toContain('yyyy M! d!');
            expect(parseFormats).toContain('yyyy/M!/d!');
            expect(parseFormats).toContain('yyyy.M!.d!');
            expect(parseFormats).toContain('yy-M!-d!');
            expect(parseFormats).toContain('yy M! d!');
            expect(parseFormats).toContain('yy/M!/d!');
            expect(parseFormats).toContain('yy.M!.d!');
        });
    })

    describe('allows relaxed parse formats from Date Style 0', function() {
        var service, dateParserService;
        var scope = build('en-AU', 'd');

        beforeEach(module(function($provide) {
            $provide.value('$rootScope', scope);
            dateParserService = getDateParserService();
            $provide.value('dateParserService', dateParserService);
        }));

        beforeEach(inject(function(dateService) {
            service = dateService;
        }));

        it('should return only 3 formats', function() {
            var parseFormats = service.getParseFormats();
            expect(parseFormats).toContain('shortDate');
            expect(parseFormats).toContain('longDate');
            expect(parseFormats).toContain('yyyy-MM-dd');
            expect(parseFormats.length).toEqual(3);
        });

        it('should not call dateParserService to set parsing format', function() {
            service.getParseFormats();

            expect(dateParserService.setParserFormat).not.toHaveBeenCalled();
        });
    });

    describe('allows relaxed parse formats from Date Style 0', function() {
        var service, dateParserService, locale;
        var scope = build('en-AU', 'd');

        beforeEach(module(function($provide) {
            $provide.value('$rootScope', scope);
            dateParserService = getDateParserService();
            $provide.value('dateParserService', dateParserService);
            locale = { DATETIME_FORMATS: { shortDate: 'd/M/y' } };
            $provide.value('$locale', locale);
        }));

        beforeEach(inject(function(dateService) {
            service = dateService;
        }));

        it('should return expanded formats', function() {
            var parseFormats = service.getExpandedParseFormats();
            expect(parseFormats).toContain('shortDate');
            expect(parseFormats).toContain('longDate');
            expect(parseFormats).toContain('yyyy-MM-dd');

            expect(parseFormats).toContain('d/M/y');
            expect(parseFormats).toContain('dd/MMM/yy');
            expect(parseFormats).toContain('dd/MMM/yyyy');
            
            expect(parseFormats.length).toEqual(10);
        });
    });

    describe('adjustTimezoneOffsetDiff method', function() {
        var service, dateParserService;
        var scope = build('en-AU', 'd');

        beforeEach(module(function($provide) {
            $provide.value('$rootScope', scope);
            dateParserService = getDateParserService();
            $provide.value('dateParserService', dateParserService);
        }));

        beforeEach(inject(function(dateService) {
            service = dateService;
        }));

        it('returns the same value if timezoneoffset is positive', function() {
            var date = new Date('10-Dec-2016 00:00:00 GMT-1000');
            var result = service.adjustTimezoneOffsetDiff(date);

            expect(result).toEqual(date);
        });

        it('returns the same value if timezoneoffset of passed value and start of day are same', function() {
            var date = new Date('10-Dec-2016 00:00:00 GMT+1000');
            var result = service.adjustTimezoneOffsetDiff(date);

            expect(result).toEqual(date);
        });
    })
});
