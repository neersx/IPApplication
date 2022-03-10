'use strict';

describe('Inprotech.Integration.PtoAccess.scheduleController', function() {
    var _controller;
    var fixture = {
        schedule: {
            id: 1
        },
        scheduleExecutions: [{}]
    };

    beforeEach(module('Inprotech.Integration.PtoAccess'));
    beforeEach(inject(function($controller) {
        _controller = function createController() {
            return $controller('scheduleController', {
                viewInitialiser: {
                    viewData: fixture
                }
            });
        };
    }));

    it('should initialise view data', function() {
        var c = _controller();
        c.$onInit();
        expect(c.viewData).toBe(fixture);
    });

    it('should initialise initialise topic options', function() {
        var c = _controller();
        c.$onInit();
        var topic1 = c.topicOptions.topics[0];
        var topic2 = c.topicOptions.topics[1];

        expect(topic1.key).toBe('definition');
        expect(topic1.title).toBe('dataDownload.schedule.definition');
        expect(topic1.params.viewData).toBe(c.viewData);

        expect(topic2.key).toBe('recent-history');
        expect(topic2.title).toBe('dataDownload.schedule.recentHistoryTitle');
        expect(topic2.params.viewData).toBe(c.viewData);
    });

    it('should show the recent history topic even if schedule has never been executed', function() {
        fixture.scheduleExecutions = [];

        var c = _controller();
        c.$onInit();
        expect(c.viewData).toBe(fixture);

        var topic1 = c.topicOptions.topics[0];

        expect(c.topicOptions.topics.length).toBe(2);
        expect(topic1.key).toBe('definition');
        expect(topic1.title).toBe('dataDownload.schedule.definition');
        expect(topic1.params.viewData).toBe(c.viewData);
    });
});