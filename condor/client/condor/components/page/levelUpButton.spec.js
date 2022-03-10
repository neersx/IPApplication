describe('levelUpButton', function() {
    'use strict';

    var controller, state, stateParams, bus, translationProvider;
    beforeEach(function() {
        module('inprotech.components.page');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.core']);

            stateParams = {};
            state = {
                current: {}
            };

            bus = $injector.get('BusMock');

            var promiseMock = $injector.get('promiseMock');
            translationProvider = promiseMock.createSpy('translated');

            $provide.value('$stateParams', stateParams);
            $provide.value('$translate', translationProvider);
            $provide.value('bus', bus);
            $provide.value('$state', state);
        });
    });

    beforeEach(function() {
        inject(function($componentController) {
            controller = function(options) {
                return $componentController('ipLevelUpButton', null, options);
            }
        });
    });

    it('initialises', function() {
        var options = {
            lastSearch: {}
        };
        var c = controller(options);
        c.$onInit();
        expect(c.lastSearch).toBeDefined();
        expect(c.levelUp).toBeDefined();
    });

    it('translates tooltip', function() {
        var c = controller();
        c.$onInit();
        expect(translationProvider).toHaveBeenCalled();
        expect(c.tooltip).toBe('translated');
    });

    describe('levelUp', function() {
        it('broadcasts message to grid', function() {
            var options = {
                lastSearch: {
                    getPageForId: jasmine.createSpy().and.returnValue({ page: 987 })
                }
            };
            stateParams.id = 123;

            var c = controller(options);
            c.$onInit();
            c.gridId = 'searchResultsGrid';
            c.levelUp();

            expect(bus.channel).toHaveBeenCalledWith('grid.searchResultsGrid');
            expect(bus.channel().broadcast).toHaveBeenCalledWith({
                rowId: 123,
                pageIndex: 987
            });
            expect(options.lastSearch.getPageForId).toHaveBeenCalledWith(123);
        });

        it('should not broadcast message if levelling sideways', function() {
            var options = {
                lastSearch: {
                    getPageForId: jasmine.createSpy().and.returnValue(987)
                },
                toState: 'workflows.inheritance'
            };

            state.current.name = 'workflows.details';

            var c = controller(options);
            c.$onInit();
            c.gridId = 'searchResultsGrid';
            c.levelUp();

            expect(bus.channel).not.toHaveBeenCalled();
        });
    });

    describe('state management', function() {
        it('derives \'to\' state from footprints', function() {
            state.current = {
                footprints: [{
                    from: {
                        name: 'from'
                    },
                    fromParams: {
                        'p': 'x'
                    }
                }]
            };
            var c = controller();
            c.$onInit();
            expect(c.toState).toBe('from');
            expect(c.stateParams).toEqual(jasmine.objectContaining({
                'p': 'x'
            }));
        });

        it('uses ui-router default level up when no state provided', function() {
            var c = controller();
            c.$onInit();
            expect(c.toState).toBe('^');
            expect(c.stateParams).toBeDefined();
        });

        it('should use hard coded state params over footprints', function() {
            var options = {
                toState: 'my.home.state.of.new.joyzey',
                additionalStateParams: {id: 1}
            }
            state.current = {
                footprints: [{
                    from: {},
                    fromParams: {}
                }]
            };
            var c = controller(options);
            c.$onInit();
            expect(c.toState).toEqual(options.toState);
            expect(c.stateParams).toEqual(options.additionalStateParams);
        });
    });
});
