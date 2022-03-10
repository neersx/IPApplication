describe('detailPageNav', function() {
    'use strict';

    var controller, state, stateParams, hotkeys, scope;
    beforeEach(function() {
        module('inprotech.components.page');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            state = $injector.get('stateMock');
            $provide.value('$state', state);
        });
    });

    beforeEach(function() {
        inject(function($rootScope, $componentController) {
            scope = $rootScope.$new();
            controller = function(options) {
                hotkeys = jasmine.createSpyObj('hotkeys', ['add', 'del']);

                stateParams = stateParams || {};
                return $componentController('ipDetailPageNav', {
                    $stateParams: stateParams,
                    $state: state,
                    hotkeys: hotkeys,
                    $scope: scope
                }, options);
            };
        });
    });

    it('initialises', function() {
        var c = controller();
        c.$onInit();
        expect(c.paramKey).toBe('id');
        expect(c.navigate).toBeDefined();
    });

    it('initialises shortcuts', function() {
        var c = controller();
        c.$onInit();
        var args = hotkeys.add.calls.allArgs();

        expect(args[0][0].combo).toBe('alt+shift+up');
        expect(args[0][0].description).toBe('shortcuts.page.first');

        expect(args[1][0].combo).toBe('alt+shift+left');
        expect(args[1][0].description).toBe('shortcuts.page.prev');

        expect(args[2][0].combo).toBe('alt+shift+right');
        expect(args[2][0].description).toBe('shortcuts.page.next');

        expect(args[3][0].combo).toBe('alt+shift+down');
        expect(args[3][0].description).toBe('shortcuts.page.last');
    });

    describe('navigate', function() {
        var ctrl;

        it('returns if no id', function() {
            ctrl = controller({
                routerState: 'detail.page'
            });
            ctrl.$onInit();
            ctrl.navigate(null);

            expect(state.go).not.toHaveBeenCalled();
        });

        it('navigates to routerState with correct paramaters', function() {
            ctrl = controller({
                routerState: 'detail.page',
                paramKey: 'detailId',
                ids: [123, 0, 234]
            });
            ctrl.$onInit();
            ctrl.navigate(123);
            expect(state.go).toHaveBeenCalledWith('detail.page', {
                detailId: 123
            });

            ctrl.navigate(0);
            expect(state.go).toHaveBeenCalledWith('detail.page', {
                detailId: 0
            });
        });

        it('navigates to routerState with correct paramaters for id objects', function() {
            ctrl = controller({
                routerState: 'caseView',
                paramKey: 'rowKey',
                ids: [{
                    key: '123',
                    value: 123
                }]
            });
            ctrl.$onInit();
            var id = '123';
            ctrl.navigate(id);

            expect(state.go).toHaveBeenCalledWith('caseView', {
                rowKey: id
            });
        });

    });

    describe('processIds sets navigation ids ', function() {
        beforeEach(function() {
            scope.$emit = jasmine.createSpy();
        });
        it('using list of ids', function() {
            stateParams = {
                id: 3
            };

            var c = controller({
                ids: [1, 2, 3, 4, 5]
            });
            c.$onInit();
            expect(c.prevId).toBe(2);
            expect(c.current).toBe(3);
            expect(c.nextId).toBe(4);
            expect(c.total).toBe(5);
            expect(c.visible).toBe(true);

            expect(scope.$emit).toHaveBeenCalledWith('detailNavigate', {
                currentPage: 2
            });
        });

        it('using list of id objects', function() {
            stateParams = {
                rowKey: '3'
            };

            var c = controller({
                ids: [{
                        key: '1',
                        value: 1
                    },
                    {
                        key: '2',
                        value: 2
                    },
                    {
                        key: '3',
                        value: 3
                    },
                    {
                        key: '4',
                        value: 4
                    },
                    {
                        key: '5',
                        value: 5
                    }
                ],
                paramKey: 'rowKey'
            });
            c.$onInit();
            expect(c.prevId).toEqual('2');
            expect(c.current).toEqual(3);
            expect(c.nextId).toEqual('4');
            expect(c.total).toEqual(5);
            expect(c.visible).toBe(true);

            expect(scope.$emit).toHaveBeenCalledWith('detailNavigate', {
                currentPage: 2
            });
        });

        it('using lastSearch', function() {
            stateParams = {
                id: 3
            };

            var lastSearch = {
                getAllIds: function() {
                    return {
                        then: function(cb) {
                            return cb([5, 4, 3, 2, 1]);
                        }
                    };
                }
            };

            var c = controller({
                lastSearch: lastSearch
            });
            c.$onInit();

            expect(c.prevId).toBe(4);
            expect(c.current).toBe(3);
            expect(c.nextId).toBe(2);
            expect(c.lastId).toBe(1);
            expect(c.total).toBe(5);
            expect(c.visible).toBe(true);
            expect(scope.$emit).toHaveBeenCalledWith('detailNavigate', {
                currentPage: 2
            });
        });

        it('using lastSearch on id objects', function() {
            stateParams = {
                rowKey: '3'
            };

            var lastSearch = {
                getAllIds: function() {
                    return {
                        then: function(cb) {
                            return cb([{
                                    key: '1',
                                    value: 1
                                },
                                {
                                    key: '2',
                                    value: 2
                                },
                                {
                                    key: '3',
                                    value: 3
                                },
                                {
                                    key: '4',
                                    value: 4
                                },
                                {
                                    key: '5',
                                    value: 5
                                }
                            ]);
                        }
                    };
                }
            };

            var c = controller({
                lastSearch: lastSearch,
                paramKey: 'rowKey'
            });
            c.$onInit();
            expect(c.firstId).toEqual('1');
            expect(c.prevId).toEqual('2');
            expect(c.current).toBe(3);
            expect(c.nextId).toEqual('4');
            expect(c.lastId).toEqual('5');
            expect(c.total).toBe(5);
            expect(c.visible).toBe(true);
            expect(scope.$emit).toHaveBeenCalledWith('detailNavigate', {
                currentPage: 2
            });
        });

        it('hidden if id does not exist in the list', function() {
            stateParams = {
                id: 9
            };
            var c = controller({
                ids: [5, 6, 7, 8]
            });
            c.$onInit();
            expect(c.current).not.toBeDefined();
            expect(c.firstId).not.toBeDefined();
            expect(c.prevId).not.toBeDefined();
            expect(c.nextId).not.toBeDefined();
            expect(c.lastId).not.toBeDefined();
            expect(c.total).not.toBeDefined();
            expect(c.visible).toBe(false);
            expect(scope.$emit).not.toHaveBeenCalled();
        });

        it('hidden if id does not exist in the list on id objects', function() {
            stateParams = {
                rowKey: '9'
            };
            var c = controller({
                ids: [{
                    key: '5',
                    value: 5
                }, {
                    key: '6',
                    value: 6
                }, {
                    key: '7',
                    value: 7
                }, {
                    key: '8',
                    value: 8
                }],
                paramKey: 'rowKey'
            });
            c.$onInit();
            expect(c.current).not.toBeDefined();
            expect(c.firstId).not.toBeDefined();
            expect(c.prevId).not.toBeDefined();
            expect(c.nextId).not.toBeDefined();
            expect(c.lastId).not.toBeDefined();
            expect(c.total).not.toBeDefined();
            expect(c.visible).toBe(false);
            expect(scope.$emit).not.toHaveBeenCalled();
        });
    });
});