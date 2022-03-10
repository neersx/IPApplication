'use strict';

var router = require('express').Router();

function buildReport(index) {
    return {
        id: index,
        title: 'Report Title ' + index,
        description: 'Report Description' + index,
        path: 'ReportPath' + index
    };
}

function buildAvailableReportCategory(category, count) {
    var reports = [];

    for (var i = 0; i < count; i++) {
        reports.push(buildReport(i));
    }

    return {
        reportCategory: category,
        reports: reports
    };
}

router.get('/api/reports/availablereportsview', function(req, res) {
    res.json({
        viewData: [
            buildAvailableReportCategory('Revenue Analysis Reports', 3),
            buildAvailableReportCategory('Sales Reports', 10),
            buildAvailableReportCategory('Other Reports', 5)
        ]
    });
});

module.exports = router;