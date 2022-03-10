angular.module('inprotech.dev').controller('BarchartController', function ($http, utils, kendoBarChartBuilder) {
    'use strict';

    var vm = this;
    vm.$onInit = onInit;

    function onInit() {
        vm.page = 0;
        vm.theme = 'theme1';
        init();
    }

    var search = function (params) {
        vm.chartOptions.theme = vm.theme;
        return $http.get('/api/dev/barchart/results', {
            params: {
                params: JSON.stringify(params)
            }
        }).then(function (response) {
            return response.data;
        });
    };

    var init = function () {
        kendoBarChartBuilder.buildOptions({
            id: 'chart',
            theme: vm.theme,
            title: {
                text: 'Chart Name'
            },
            categoryAxis: {
                title: {
                    text: 'Horizontal Axis Title'
                },
                field: 'category'
            },
            valueAxis: {
                title: {
                    text: 'Value Axix Title'
                }
            },
            seriesDefaults: {
                type: "column",
                stack: true
            },
            series: [{
                field: 'Bar1',
                name: 'Title for Bar 1',
                gap: 0.5,
                spacing: 0.05
            }, {
                field: 'Bar2',
                name: 'Title for Bar 2'
            }, {
                field: 'Bar3',
                name: 'Title for Bar 3'
            }, {
                field: 'Bar4',
                name: 'Title for Bar 4'
            }],
            seriesClick: function (e) {
                vm.seriesClicked(e);
            },
            read: vm.refreshData
        }).then(function (options) {
            vm.chartOptions = options;
            search({
                page: vm.page
            });
        });
    };

    vm.refreshData = function () {
        return search({
            page: ++vm.page
        });
    };

    vm.changeTheme = function () {
        if (vm.theme === 'theme1') {
            vm.theme = 'theme2';
        } else {
            vm.theme = 'theme1';
        }

        return search({
            page: ++vm.page
        });
    };

    vm.seriesClicked = function (e) {
        utils.debug('Clicked Item: \n' + 'DataItem:  Bar1: ' + e.dataItem.Bar1 + ' Bar 2:' + e.dataItem.Bar2);
        utils.debug('Id:' + e.dataItem.id);
        utils.debug('Category:' + e.category);
        utils.debug('Bar:' + e.series.field);
    };   

    //The following code is under consideration of being added to design guide

    kendo.dataviz.ui.registerTheme('theme1', {
        chart: {
            legend: {
                labels: {
                    color: '#777777'
                }
            },
            chartArea: {},
            seriesDefaults: {
                labels: {
                    color: '#000'
                }
            },
            axisDefaults: {
                line: {
                    color: '#c7c7c7'
                },
                labels: {
                    color: '#777777'
                },
                minorGridLines: {
                    color: '#c7c7c7'
                },
                majorGridLines: {
                    color: '#c7c7c7'
                },
                title: {
                    color: '#777777'
                }
            },
            seriesColors: [
                '#cda1133', '#d43851', '#818181', '#110110'
            ],
            tooltip: {
                background: '#fff',
                color: '#000'
            }
        }
    });

    kendo.dataviz.ui.registerTheme('theme2', {
        chart: {
            legend: {
                labels: {
                    color: '#111111'
                }
            },
            chartArea: {},
            seriesDefaults: {
                labels: {
                    color: '#bbb'
                }
            },
            axisDefaults: {
                line: {
                    color: '#7cc77c'
                },
                labels: {
                    color: '#444444'
                },
                minorGridLines: {
                    color: '#c7c7c7'
                },
                majorGridLines: {
                    color: '#c7c7c7'
                },
                title: {
                    color: '#777777'
                }
            },
            series: {
                overlay: {
                    gradient: 'none'
                }
            },
            seriesColors: [
                '#ddddcc', '#00dd00', '#818181', '#5501FF'
            ],
            tooltip: {
                background: '#fff',
                color: '#000'
            }
        }
    });
});

