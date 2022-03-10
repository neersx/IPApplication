describe('inprotech.processing.policing.rateGraphItemFormatterService', function() {
    'use strict';

    /* eslint no-undef: 0 */
    var service, _moment, defaultMoment;

    beforeEach(function() {
        module('inprotech.processing.policing');

        /* eslint no-undef: 0 */
        defaultMoment = window.moment;

        window.moment = _moment = function() {
            return _moment;
        };
        _moment.startOf = function() {
            return _moment;
        };
        _moment.diff = function() {
            return _moment;
        };

        module(function($provide) {
            var dateService = {
                dateFormat: 'dd-MMM-yy'
            };

            $provide.value('dateService', dateService);
        });
    });

    afterEach(function() {
        window.moment = defaultMoment;
    });

    beforeEach(inject(function(rateGraphItemFormatterService) {
        service = rateGraphItemFormatterService;
    }));

    describe('when format is called', function() {
        it('should format timeslot to date and time format if not todays date', function() {
            var items = [{
                id: 2,
                timeSlot: '2015-09-12T10:10:10.000'
            }];

            var expectedTime = '10:10';
            var expectedDate = '12-Sep-15';

            var result = service.format(items);

            expect(result[0].timeSlotLabel.substring(0, 5)).toBe(expectedTime);
            expect(result[0].timeSlotLabel.substring(6)).toBe(expectedDate);
        });
    });
});