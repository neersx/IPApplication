describe('inprotech.components.grid.directives.ipKendoGridKeyboardShortcuts', function() {
    'use strict';

    var c, el, defaultGridOptions;
    beforeEach(function() {
        module('inprotech.components.grid');
    });

    beforeEach(inject(function(ipKendoGridKeyboardShortcuts) {
        c = ipKendoGridKeyboardShortcuts;
        el = angular.element('<div id="test"></div>');
        defaultGridOptions = getDefaultGridOptions();
    }));

    function getDefaultGridOptions() {
        var pageSpy = jasmine.createSpy();
        var totalPagesSpy = jasmine.createSpy();
        var gridOptions = {
            dataSource: {
                page: pageSpy.and.returnValue(3),
                totalPages: totalPagesSpy.and.returnValue(5)
            },
            onDataBound: jasmine.createSpy()
        };

        return {
            gridOptions: gridOptions,
            pageSpy: pageSpy,
            totalPagesSpy: totalPagesSpy
        };
    }

    describe('kendo grid keyboard shortcuts', function() {
        it('has a bind shortcut method', function() {
            expect(c.bindShortcuts).toBeDefined();
        });
    });

    describe('bind shortcut method', function() {
        it('binds events to element', function() {
            c.bindShortcuts('test', el, defaultGridOptions.gridOptions);
            var events = $._data(el[0], "events");
            expect(events.setFocus).toBeDefined();
            expect(events.nextPage).toBeDefined();
            expect(events.previousPage).toBeDefined();
            expect(events.firstPage).toBeDefined();
            expect(events.lastPage).toBeDefined();
            expect(events.select).toBeDefined();
            expect(events.keydown).toBeDefined();
        });

        it('prevents default behaviour when triggered', function() {
            c.bindShortcuts('test', el, defaultGridOptions);
            var ev = {
                type: 'keydown',
                keyCode: 13,
                preventDefault: jasmine.createSpy()
            };
            el.trigger(ev);
            expect(ev.preventDefault).toHaveBeenCalled();
        })
    });

    describe('grid event triggers', function() {
        it('navigates to first page', function() {
            c.bindShortcuts('test', el, defaultGridOptions.gridOptions);
            el.trigger('firstPage');
            expect(defaultGridOptions.pageSpy).toHaveBeenCalledWith(1);
        });

        it('navigates to previous page', function() {
            c.bindShortcuts('test', el, defaultGridOptions.gridOptions);
            el.trigger('previousPage');
            expect(defaultGridOptions.pageSpy).toHaveBeenCalledWith(2);
        });

        it('navigates to next page', function() {
            c.bindShortcuts('test', el, defaultGridOptions.gridOptions);
            el.trigger('nextPage');
            expect(defaultGridOptions.pageSpy).toHaveBeenCalledWith(4);
        });

        it('navigates to the last page', function() {
            c.bindShortcuts('test', el, defaultGridOptions.gridOptions);
            el.trigger('lastPage');
            expect(defaultGridOptions.pageSpy).toHaveBeenCalledWith(5);
        });

        it('executes gridOptions onSelect', function() {
            var gridOptions = {
                onSelect: jasmine.createSpy()
            };
            c.bindShortcuts('test', el, gridOptions);
            el.trigger('select');
            expect(gridOptions.onSelect).toHaveBeenCalled();
        });

        it('does not executed onSelect when disabled', function(){
            var gridOptions = {
                onSelect: jasmine.createSpy()
            };
            gridOptions.onSelect.disabled = true;
            c.bindShortcuts('test', el, gridOptions);
            el.trigger('select');
            expect(gridOptions.onSelect).not.toHaveBeenCalled();
        });

        describe('setFocus', function() {
            var kendoObject;
            var cell = {};
            beforeEach(function() {
                kendoObject = {
                    current: jasmine.createSpy(),
                    tbody: {
                        find: jasmine.createSpy().and.returnValue(cell)
                    },
                    table: {
                        focus: jasmine.createSpy(),
                        closest: function() {
                            return {
                                prev: function() {
                                    return {
                                        length: 0
                                    };
                                }
                            };
                        }
                    },
                    dataSource: {
                        total: jasmine.createSpy().and.returnValue(5)
                    }
                };
                spyOn($.fn, 'data').and.returnValue(kendoObject);
            });

            it('sets focus on grid when triggered externally and only when there are results', function() {
                c.bindShortcuts('test', el, defaultGridOptions.gridOptions);
                el.trigger('setFocus');
                expect(kendoObject.current).toHaveBeenCalledWith(cell);
                expect(kendoObject.table.focus).toHaveBeenCalled();

                kendoObject.table.focus.calls.reset();
                kendoObject.dataSource.total.and.returnValue(0);
                el.trigger('setFocus');
                expect(kendoObject.table.focus).not.toHaveBeenCalled();
            });
        });
    });
});
