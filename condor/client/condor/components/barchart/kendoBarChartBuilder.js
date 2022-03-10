angular.module('inprotech.components.barchart').factory('kendoBarChartBuilder', function($q, $translate) {
    'use strict';

    var defaultOptions = {
        id: null,
        title: {
            text: null
        },
        legend: {
            position: 'top'
        },
        seriesDefaults: {
            type: 'column'
        },
        valueAxis: {
            title: {
                text: null
            },
            labels: {
                format: '{0}'
            }
        },
        line: {
            visible: false
        },
        categoryAxis: {
            title: {
                text: null
            },
            line: {
                visible: false
            },
            labels: {
                padding: {
                    top: 5
                }
            }
        },
        tooltip: {
            visible: true,
            format: '{0}',
            template: '#= value #: #= series.name #'
        },
        render: function(e) {
            setTimeout(function() {
                var loading = $('.chart-loading', e.sender.element.parent());
                kendo.ui.progress(loading, false);
            });
        },
        transitions: true,
        refreshData: angular.noop,
        refreshChart: angular.noop
    };

    return {
        buildOptions: buildKendoBarChartOptions
    };

    function buildKendoBarChartOptions(chartOptions) {
        chartOptions = angular.merge({}, defaultOptions, chartOptions);

        var dataSourceOptions = initGraphDataSourceOptions(chartOptions);
        chartOptions.dataSource = new kendo.data.DataSource(dataSourceOptions);

        setRefresh(chartOptions);
        setRefreshChart(chartOptions);

        return $q.when(translateTexts(chartOptions)).then(function() {
            return chartOptions;
        });
    }

    function translateTexts(chartOptions) {
        var texts = [chartOptions.title, chartOptions.categoryAxis.title, chartOptions.valueAxis.title];

        _.each(texts, function(t) {
            if (t.text) {
                translateText(t.text).then(function(translatedText) {
                    t.text = translatedText;
                });
            }
        });

        _.each(chartOptions.series, function(s) {
            if (s.name) {
                translateText(s.name).then(function(translatedText) {
                    s.name = translatedText;
                });
            }
        });

        if (chartOptions.categoryAxis.translateCategories) {
            _.each(chartOptions.categoryAxis.categories, function(c, index) {
                translateText(c).then(function(translatedText) {
                    chartOptions.categoryAxis.categories[index] = translatedText;
                });
            });
        }

        return null;
    }

    function translateText(text) {
        return $q.when($translate(text));
    }

    function initGraphDataSourceOptions(chartOptions) {
        return {
            transport: {
                read: function(e) {
                    kendo.ui.progress($('.chart-loading'), true);
                    return $q.when(chartOptions.read()).then(function(data) {
                        if (data) {
                            e.success(data);
                        } else {
                            kendo.ui.progress($('.chart-loading'), false);
                            e.error();
                        }
                    });
                }
            }
        };
    }

    function setRefresh(chartOptions) {
        chartOptions.refreshData = function() {
            chartOptions.dataSource.read();
        };
    }

    function setRefreshChart(chartOptions) {
        chartOptions.refreshChart = function() {
            $('#' + chartOptions.id).data('kendoChart').refresh();
        };
    }
});
