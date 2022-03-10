describe('inprotech', function() {
    'use strict';

    var rootScope, translateFilter, transitions, state;
    var transParam, to, from, toParams, fromParams;

    beforeEach(function() {
        module('inprotech');
        module(function($provide) {
            translateFilter = jasmine.createSpy('translateFilter', function(val) {
                return val;
            }).and.callThrough();
            $provide.value('translateFilter', translateFilter);
            transitions = test.mock('$transitions', 'transitionsMock');
            state = test.mock('$state', 'stateMock');
        });

        inject(function($rootScope) {
            rootScope = $rootScope;

            to = {
                name: 'to'
            };
            from = {
                name: 'from'
            };
            toParams = {};
            fromParams = {};
            transParam = {
                to: function() {
                    return to;
                },
                from: function() {
                    return from;
                },
                params: function(from) {
                    if (from) {
                        return fromParams;
                    } else {
                        return toParams;
                    }
                }
            };

        });
    });

    describe('state change success', function() {
        it('should register footprints', function() {
            transitions.executeCallBackFor('onEnter', 'footprintsListenerOnEnter', transParam, { name: transParam.to.name });
            expect(to.footprints).toBeDefined();
        });

        it('should add footprint when navigating', function() {
            from.footprints = [];
            to.name = 'from.to';
            transitions.executeCallBackFor('onEnter', 'footprintsListenerOnEnter', transParam, { name: to.name });
            expect(to.footprints[0].from).toBe(from);
            expect(to.footprints[0].fromParams).toEqual(fromParams);
        });

        it('should remove footprint when navigating back', function() {
            // 'from' came from 'to'
            from.footprints = [{
                from: to,
                fromParams: toParams
            }];

            // level up
            transitions.executeCallBackFor('onEnter', 'footprintsListenerOnEnter', transParam, { name: transParam.to.name });

            expect(to.footprints.length).toEqual(0);
            expect(from.footprints.length).toEqual(0);
        });

        it('should remove footprint when navigating back to status, which is retained', function() {
            to.footprints = [{
                from: to,
                fromParams: toParams
            }];
            from.footprints = [{
                from: to,
                fromParams: toParams
            }];

            transitions.executeCallBackFor('onRetain', 'footprintsListenerOnRetain', transParam, { name: transParam.to.name });
            expect(to.footprints.length).toEqual(0);
        });

        it('should not change footprints if refreshing same page', function() {
            to.footprints = [{
                from: { name: 'a' },
                fromParams: 'b'
            }];
            from = to;
            toParams = {
                'someParam': 'abc'
            };
            fromParams = {
                'someParam': 'abc'
            };

            transitions.executeCallBackFor('onEnter', 'footprintsListenerOnEnter', transParam, { name: transParam.to.name });

            expect(to).toEqual(from);
        });

        it('should change paramaters for footprints if same page is loaded with different parameters', function() {
            to.footprints = [{
                from: { name: 'to' },
                fromParams: {
                    'someParam': 'xyz',
                    'otherParam': 'jack'
                }
            }];
            from = to;
            fromParams = {
                'someParam': 'xyz',
                'otherParam': 'jack'
            };
            toParams = {
                'someOtherParam': 'jill',
                'someParam': 'abc'
            };

            transitions.executeCallBackFor('onEnter', 'footprintsListenerOnEnter', transParam, { name: transParam.to.name });

            expect(to.footprints[0].fromParams).toEqual({
                'someParam': 'abc',
                'otherParam': 'jack'
            });
        });
    });

    describe('title listener', function() {
        it('should translate the page title', function() {
            state.current = {
                name: 'a',
                data: {
                    pageTitle: 'My Little Pony'
                }
            };

            transitions.executeCallBackFor('onSuccess', 'titleListener', transParam);

            expect(translateFilter).toHaveBeenCalledWith(state.current.data.pageTitle);
            expect(window.document.title).toEqual(state.current.data.pageTitle + ' - Inprotech');
        });

        it('should set translated title and prefix if provided', function() {
            state.current = {
                name: 'a',
                data: {
                    pageTitle: 'My Little Pony',
                    pageTitlePrefix: 'Some number'
                }
            };

            transitions.executeCallBackFor('onSuccess', 'titleListener', transParam);

            expect(translateFilter).toHaveBeenCalledWith(state.current.data.pageTitle);
            expect(window.document.title).toEqual(state.current.data.pageTitlePrefix + ' - ' + state.current.data.pageTitle + ' - Inprotech');
        });

        it('should set prefix from external function', function() {
            var prefix = 'Some number';
            state.current = {
                name: 'a'
            };

            rootScope.setPageTitlePrefix(prefix);

            expect(window.document.title).toEqual(prefix + ' - Inprotech');
            expect(state.current.data).toBeDefined();
            expect(state.current.data.pageTitlePrefix).toBe(prefix);
        });

        it('should set prefix if provided', function() {
            state.current = {
                name: 'a',
                data: {
                    pageTitlePrefix: 'Some number'
                }
            };

            transitions.executeCallBackFor('onSuccess', 'titleListener', transParam);

            expect(translateFilter).not.toHaveBeenCalled();
            expect(window.document.title).toEqual(state.current.data.pageTitlePrefix + ' - Inprotech');
        });

        it('should set prefix if provided, for the given state', function() {
            var stateProvided = {};
            var prefix = 'Some number';
            state.get = function() {
                return stateProvided;
            };
            state.current = stateProvided;

            rootScope.setPageTitlePrefix(prefix, 'somestate');

            expect(window.document.title).toEqual(prefix + ' - Inprotech');
            expect(stateProvided.data.pageTitlePrefix).toBe(prefix);
        });

        it('should clean the title prefix on exit, if navigating to different states', function() {
            from = {
                name: 'a',
                data: {
                    pageTitlePrefix: 'crazy'
                }
            };

            to = {
                name: 'toto'
            };

            transitions.executeCallBackFor('onExit', 'titlePrefixCleaner', transParam);
            expect(from.data.pageTitlePrefix).toBeNull();
        });
    });

    describe('page css adder listener', function() {
        it('should set the page css class name by convention', function() {
            to.name = 'parentNamespace.childNamespace.grandchildNamespace';

            transitions.executeCallBackFor('onSuccess', 'addPageCssClass', transParam);

            expect(rootScope.pageCssClass).toEqual('parent-namespace child-namespace grandchild-namespace');
        });
    });
});