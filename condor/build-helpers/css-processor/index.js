'use strict';

var tap = require('gulp-tap');
var rework = require('rework');
var reworkUrl = require('rework-plugin-url');
var path = require('path');
var url = require('url');
var util = require('gulp-util');
var fs = require('fs');

// Plugin level function(dealing with files)
function processCssForAssets(stream, assets) {
    return stream.pipe(tap(function(file) {
        var cssFile = file.path;
        var cssFolder = path.dirname(cssFile);
        util.log('[Include css] ' + cssFile);
        if (file.contents) {
            var newCss = rework(file.contents.toString(), {
                    source: file.path
                })
                .use(reworkUrl(function(cssUrl) {
                    if (/^data:/i.test(cssUrl)) {
                        return cssUrl;
                    }

                    var parsed = url.parse(cssUrl);
                    var filename = path.basename(cssUrl);
                    var absPath = path.isAbsolute(parsed.pathname) ? parsed.pathname : path.resolve(path.join(cssFolder, parsed.pathname));
                    var clientAssetPath = 'assets/' + filename;

                    if (assets.indexOf(absPath) === -1) {
                        if(fs.existsSync(absPath)) {
                            util.log('[Include asset]: ' + absPath);
                            assets.push(absPath);
                        } else {
                            util.log(util.colors.yellow('[Asset not found]: ' + absPath));
                        }
                    }
                    return clientAssetPath;
                }))
                .toString();

            file.contents = new Buffer(newCss);
        }
    }));
}

// Exporting the plugin main function
module.exports = processCssForAssets;
