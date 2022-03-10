describe('inprotech.processing.policing.statusGraphDataAdapterService', function() {
    'use strict';

    var service;

    beforeEach(function() {
        module('inprotech.processing.policing');
    });

    beforeEach(inject(function(statusGraphDataAdapterService) {
        service = statusGraphDataAdapterService;
    }));

    describe('when getCategories is called for normal categories', function() {
        it('should return categories for the graph', function() {

            var result = service.getCategories(false);

            expect(result[0]).toBe('waiting-to-start');
            expect(result[1]).toBe('in-progress');
        });
    });

    describe('when getCategories is called for error categories', function() {
        it('should return categories for the graph', function() {

            var result = service.getCategories(true);

            expect(result[0]).toBe('blocked');
            expect(result[1]).toBe('failed');
            expect(result[2]).toBe('in-error');
        });
    });

    describe('when prioritiseStatus is called for normal categories', function() {

        function build(s, t, f) {
            return {
                'stuck': s,
                'tolerable': t,
                'fresh': f,
                'total': s + t + f
            };
        }

        it('should return data in status order', function() {

            var waitingToStart = build(1, 1, 3);

            var inProgress = build(1, 1, 15);

            var data = {
                'inProgress': inProgress,
                'waitingToStart': waitingToStart
            };

            var result = service.prioritiseStatus(data, false);

            expect(result[0]).toEqual({
                'stuck': 1,
                'tolerable': 1,
                'fresh': 3,
                'total': 5
            });

            expect(result[1]).toEqual({
                'stuck': 1,
                'tolerable': 1,
                'fresh': 15,
                'total': 17
            });

            expect(result.length).toBe(2);
        });

        it('should remove zero-valued items to make graph look un-hanging', function() {

            var waitingToStart = build(1, 0, 3);

            var inProgress = build(0, 0, 0);

            var data = {
                'inProgress': inProgress,
                'waitingToStart': waitingToStart
            };

            var result = service.prioritiseStatus(data, false);

            expect(result[0]).toEqual({
                'stuck': 1,
                'fresh': 3,
                'total': 4
            });

            expect(result[1]).toEqual({});
        });
    });

    describe('when prioritiseStatus is called for error categories', function() {

        function build(s, t, f) {
            return {
                'stuck': s,
                'tolerable': t,
                'fresh': f,
                'total': s + t + f
            };
        }

        it('should return data in status order', function() {

            var blocked = build(3, 4, 5);

            var failed = build(15, 4, 6);

            var inError = build(30, 30, 30);

            var data = {
                'inError': inError,
                'failed': failed,
                'blocked': blocked
            };

            var result = service.prioritiseStatus(data, true);

            expect(result[0]).toEqual({
                'stuck': 3,
                'tolerable': 4,
                'fresh': 5,
                'total': 12
            });

            expect(result[1]).toEqual({
                'stuck': 15,
                'tolerable': 4,
                'fresh': 6,
                'total': 25
            });

            expect(result[2]).toEqual({
                'stuck': 30,
                'tolerable': 30,
                'fresh': 30,
                'total': 90
            });

            expect(result.length).toBe(3); 
        });

        it('should remove zero-valued items to make graph look un-hanging', function() {

            var blocked = build(4, 0, 0);

            var failed = build(0, 4, 6);

            var inError = build(0, 0, 0);

            var data = {
                'inError': inError,
                'failed': failed,
                'blocked': blocked
            };

            var result = service.prioritiseStatus(data, true);

            expect(result[0]).toEqual({
                'stuck': 4,
                'total': 4
            });

            expect(result[1]).toEqual({
                'tolerable': 4,
                'fresh': 6,
                'total': 10
            });

            expect(result[2]).toEqual({});
        });
    });
});
