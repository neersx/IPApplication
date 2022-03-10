describe('inprotech.components.form.dateService', function() {
    'use strict';

    var service, _moment;

    beforeEach(module('inprotech.core'));
    beforeEach(inject(function(dateHelper) {
        service = dateHelper;

        _moment = window.moment; // eslint-disable-line
        spyOn(_moment, 'utc').and.callThrough();
    }));

    describe('convertForDatePicker method', function() {
        it('converts a date string to a date object', function() {
            var dateString = '2017-01-01';
            var result = service.convertForDatePicker(dateString);

            expect(_moment.utc).toHaveBeenCalled();
            expect(result.getFullYear()).toBe(2017);
            expect(result.getMonth()).toBe(0);
            expect(result.getDate()).toBe(1);
        });

        it('does not convert if already a date object', function() {
            var dateObj = new Date('2017-01-01T00:00:00');
            var result = service.convertForDatePicker(dateObj);

            expect(_moment.utc).not.toHaveBeenCalled();
            expect(result.getFullYear()).toBe(2017);
            expect(result.getMonth()).toBe(0);
            expect(result.getDate()).toBe(1);
        });
    });
});