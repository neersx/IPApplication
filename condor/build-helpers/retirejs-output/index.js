'use strict';

var fs = require('fs');
var path = require('path');
var util = require('gulp-util');
var _ = require('underscore');

module.exports = load;

function load(options) {
    var cwd = options.cwd || process.cwd();
    var retireJsOutput = path.join(cwd, options.jsonOutput);
    if (!fs.existsSync(retireJsOutput)) {
        return;
    }

    fs.readFile(retireJsOutput, function(err, data) {
        if (err) throw err;
        var flatten = [];
        _.each(JSON.parse(data), function(m) {
            _.each(m.results, function(r) {
                _.each(r.vulnerabilities, function(v) {
                    flatten.push({
                        file: m.file,
                        basename: path.basename(m.file),
                        component: r.component,
                        version: r.version,
                        severity: v.severity,
                        severityLevel: severityLevel(v.severity),
                        summary: v.identifiers.summary
                    });
                })
            });
        });

        _.each(_.sortBy(flatten, 'severityLevel'), displayVulnerability);

        if (_.any(flatten, function(v) {
                return v.severity === 'critical' || v.severity === 'high';
            })) {
            throw "Critical/High security vulnerability detected in 3rd party libraries!";
        }
    });
}

function displayVulnerability(v) {
    util.log('[Security vulnerability]: ' + color(v.severity)('[' + v.severity + '] ' + v.component + '@' + v.version + ' - ' + v.summary) + ' in ' + v.basename);
}

function color(severity) {
    var r;
    switch (severity) {
        case 'critical':
        case 'high':
            r = util.colors.red;
            break;
        case 'medium':
            r = util.colors.magenta;
            break;
        default:
            r = util.colors.yellow;
            break;
    }
    return r;
}

function severityLevel(severity) {
    var r;
    switch (severity) {
        case 'critical':
            r = 0;
            break;
        case 'high':
            r = 1;
            break;
        case 'medium':
            r = 2;
            break;
        default:
            r = 10;
            break;
    }
    return r;
}