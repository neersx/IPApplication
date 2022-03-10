namespace inprotech.components.grid {
    describe('inprotech.components.grid.columnFilterHelper', function () {
        'use strict';

        let helper: ColumnPickerHelper, store, localSettings: inprotech.core.LocalSettings, gridOptions;
        beforeEach(function () {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
                store = $injector.get('storeMock');
            });

            inject(function () {
                localSettings = new inprotech.core.LocalSettings(store);
                helper = new ColumnPickerHelper();
            });

            gridOptions = {
                columns: getDefaultColumns(),
                columnSelection: {
                    localSetting: localSettings.Keys.caseView.actions.eventsColumnsSelection,
                    localSettingSuffix: 'test'
                }
            };
        });


        function getDefaultColumns() {
            return [{
                title: 'eventDescription',
                field: 'eventDescription',
                fixed: true,
                menu: true
            }, {
                title: 'eventDate',
                field: 'eventDate',
                fixed: true,
                menu: true
            }, {
                title: 'cycle',
                field: 'cycle',
                menu: true
            }, {
                title: 'period',
                field: 'period',
                menu: true,
                hidden: true
            }, {
                title: 'responsibility',
                field: 'responsibility',
                menu: true,
                hidden: true
            }
            ];
        }

        function reducedDefaultColumns() {
            return _.map(getDefaultColumns(), (col: any) => {
                return { field: col.field, hidden: col.hidden || false }
            });
        }

        function localStorageValue() {
            return localSettings.Keys.caseView.actions.eventsColumnsSelection.getLocal;
        }

        function localStorageValueWithSuffix() {
            return localSettings.Keys.caseView.actions.eventsColumnsSelection.getLocalwithSuffix(gridOptions.columnSelection.localSettingSuffix);
        }

        describe('init column selection', function () {
            it('should return same columns if nothing is stored in the local cache', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                let result = r.initColumnDisplay(gridOptions.columns);

                expect(result).toEqual(getDefaultColumns());
            });
            it('should store the initial columns in memory', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                r.initColumnDisplay(gridOptions.columns);

                expect(r.defaultColumns).toEqual(reducedDefaultColumns());
            });

            it('should not store the initial columns in local storage', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                r.initColumnDisplay(gridOptions.columns);

                expect(localStorageValue()).toBeUndefined();
            });
            it('should initialize columns from local storage', function () {
                localSettings.Keys.caseView.actions.eventsColumnsSelection.setLocal([{
                    field: 'eventDescription',
                    hidden: false
                }, {
                    field: 'cycle',
                    hidden: false
                }, {
                    field: 'eventDate',
                    hidden: true
                }, {
                    field: 'responsibility',
                    hidden: true
                }, {
                    field: 'period',
                    hidden: false
                }]);
                let r = helper.init(gridOptions.columnSelection.localSetting);
                let result = r.initColumnDisplay(gridOptions.columns);

                expect(result).toEqual([{
                    title: 'eventDescription',
                    field: 'eventDescription',
                    fixed: true,
                    menu: true,
                    hidden: false
                }, {
                    title: 'cycle',
                    field: 'cycle',
                    menu: true,
                    hidden: false
                }, {
                    title: 'eventDate',
                    field: 'eventDate',
                    fixed: true,
                    menu: true,
                    hidden: true
                }, {
                    title: 'responsibility',
                    field: 'responsibility',
                    menu: true,
                    hidden: true
                }, {
                    title: 'period',
                    field: 'period',
                    menu: true,
                    hidden: false
                }
                ]);
            });

        });

        describe('Update order and show hide Columns', function () {
            it('should update column order', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                r.initColumnDisplay(gridOptions.columns);
                r.updateColumnOrder(1, 4, gridOptions.columns[1]);

                expect(localStorageValue()[4]).toEqual(reducedDefaultColumns()[1]);
                expect(localStorageValue()[1]).toEqual(reducedDefaultColumns()[2]);
            });

            it('should hide column', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                r.initColumnDisplay(gridOptions.columns);
                r.hideColumn(getDefaultColumns()[1]);

                expect(localStorageValue()[1]).toEqual(_.extend({}, reducedDefaultColumns()[1], { hidden: true }));
            });

            it('should show column', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                r.initColumnDisplay(gridOptions.columns);
                r.showColumn(getDefaultColumns()[3]);

                expect(localStorageValue()[3]).toEqual(_.extend({}, reducedDefaultColumns()[3], { hidden: false }));
            });
        });

        describe('reset columns to default', function () {
            it('should reset column order', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                r.initColumnDisplay(gridOptions.columns);
                r.updateColumnOrder(1, 4, gridOptions.columns[1]);

                expect(localStorageValue()[4]).toEqual(reducedDefaultColumns()[1]);
                expect(localStorageValue()[1]).toEqual(reducedDefaultColumns()[2]);

                r.reset();
                expect(localStorageValue()).toBeUndefined();
            });

            it('should reset visibility of columns', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                r.initColumnDisplay(gridOptions.columns);
                r.hideColumn(getDefaultColumns()[1]);
                r.showColumn(getDefaultColumns()[3]);

                expect(localStorageValue()[1]).toEqual(_.extend({}, reducedDefaultColumns()[1], { hidden: true }));
                expect(localStorageValue()[3]).toEqual(_.extend({}, reducedDefaultColumns()[3], { hidden: false }));

                r.reset();
                expect(localStorageValue()).toBeUndefined();
            });

            it('should reset visibility of columns with suffix', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting, gridOptions);
                r.initColumnDisplay(gridOptions.columns);
                r.hideColumn(getDefaultColumns()[1]);
                r.showColumn(getDefaultColumns()[3]);

                expect(localStorageValueWithSuffix()[1]).toEqual(_.extend({}, reducedDefaultColumns()[1], { hidden: true }));
                expect(localStorageValueWithSuffix()[3]).toEqual(_.extend({}, reducedDefaultColumns()[3], { hidden: false }));

                r.reset();
                expect(localStorageValueWithSuffix()).toBeUndefined();
            });

            it('should reset visibility and order of columns', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting);
                r.initColumnDisplay(gridOptions.columns);
                r.hideColumn(getDefaultColumns()[1]);
                r.showColumn(getDefaultColumns()[3]);


                expect(localStorageValue()[1]).toEqual(_.extend({}, reducedDefaultColumns()[1], { hidden: true }));
                expect(localStorageValue()[3]).toEqual(_.extend({}, reducedDefaultColumns()[3], { hidden: false }));

                r.updateColumnOrder(1, 4, gridOptions.columns[1]);

                expect(localStorageValue()[4]).toEqual(_.extend({}, reducedDefaultColumns()[1], { hidden: true }));
                expect(localStorageValue()[1]).toEqual(reducedDefaultColumns()[2]);

                r.reset();
                expect(localStorageValue()).toBeUndefined();
            });

            it('should reset visibility and order of columns with suffix', function () {
                let r = helper.init(gridOptions.columnSelection.localSetting, gridOptions.columnSelection.localSettingSuffix);
                r.initColumnDisplay(gridOptions.columns);
                r.hideColumn(getDefaultColumns()[1]);
                r.showColumn(getDefaultColumns()[3]);


                expect(localStorageValueWithSuffix()[1]).toEqual(_.extend({}, reducedDefaultColumns()[1], { hidden: true }));
                expect(localStorageValueWithSuffix()[3]).toEqual(_.extend({}, reducedDefaultColumns()[3], { hidden: false }));

                r.updateColumnOrder(1, 4, gridOptions.columns[1]);

                expect(localStorageValueWithSuffix()[4]).toEqual(_.extend({}, reducedDefaultColumns()[1], { hidden: true }));
                expect(localStorageValueWithSuffix()[1]).toEqual(reducedDefaultColumns()[2]);

                r.reset();
                expect(localStorageValueWithSuffix()).toBeUndefined();
            });
        });
    });
}