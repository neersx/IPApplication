'use strict';

describe('Inprotech.Integration.PtoAccess.failureSummaryController', function() {

    var controller;

    beforeEach(
        module(function() {
            test.mock('modalService');
        }));

    beforeEach(function() {
        module('inprotech.classic');
        module('Inprotech.Integration.PtoAccess')

        inject(function($controller) {
            controller = function(params) {
                return $controller('failureSummaryController', {
                    viewInitialiser: {
                        viewData: params
                    }
                });

            };
        })
    });

    describe('initialise', function() {
        it('should set up the overview topic with each source', function() {
            var vm = controller({
                failureSummary: [{
                    dataSource: 'a',
                    failedCount: 20
                }, {
                    dataSource: 'b',
                    failedCount: 0
                }]
            })
            vm.$onInit();
            expect(vm.topicOptions.topics[0].key).toEqual('overviewGroup');
            expect(vm.topicOptions.topics[0].topics[0].key).toEqual('a');
            expect(vm.topicOptions.topics[0].topics[1].key).toEqual('b');
            expect(vm.topicOptions.topics.length).toEqual(1);
        });

        it('should set up the diagnostic topic', function() {
            var vm = controller({
                failureSummary: [{
                    dataSource: 'a',
                    failedCount: 20
                }],
                allowDiagnostics: true
            })
            vm.$onInit();
            expect(vm.topicOptions.topics[1].key).toEqual('diagnostics');
        });
    });
});