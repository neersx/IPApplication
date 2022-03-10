/**/
'use strict';

/* imports */
var gulp = require('gulp');
var path = require('path');
var extend = require('util')._extend;
var CacheBuster = require('gulp-cachebust');
var exec = require('child_process').exec;
var tslint = require("gulp-tslint");
var fs = require('fs');
var util = require('gulp-util');
var spawn = require('child_process').spawn;

var g = {};
define(g, 'karma');
define(g, 'if', 'gulp-if');
define(g, 'sass', 'gulp-sass');
define(g, 'del');
define(g, 'dom', 'gulp-dom-src');
define(g, 'sourcemaps', 'gulp-sourcemaps');
define(g, 'concat', 'gulp-concat');
define(g, 'ngAnnotate', 'gulp-ng-annotate');
define(g, 'uglify', 'gulp-uglify');
define(g, 'gzip', 'gulp-gzip');
define(g, 'rename', 'gulp-rename');
define(g, 'eslint', 'gulp-eslint');
define(g, 'util', 'gulp-util');
define(g, 'cssmin', 'gulp-cssmin');
define(g, 'htmlmin', 'gulp-htmlmin');
define(g, 'ngTemplates', 'gulp-ng-templates');
define(g, 'cheerio', 'gulp-cheerio');
define(g, 'merge', 'merge2');
define(g, 'includeJs', './build-helpers/include-js');
define(g, 'includeNg', './build-helpers/include-ng');
define(g, 'liveserver', 'gulp-live-server');
define(g, 'cssProcessor', './build-helpers/css-processor');
define(g, 'jsMinSrc', './build-helpers/js-min-src');
define(g, 'copyJsMinSrc', './build-helpers/copy-js');
define(g, 'retirejsOutput', './build-helpers/retirejs-output');
define(g, 'connect', 'gulp-connect');
define(g, 'proxy', 'http-proxy-middleware');
define(g, 'tap', 'gulp-tap');
define(g, 'mergeStream', 'merge-stream');
define(g, 'jsonMerge', 'gulp-merge-json');
define(g, 'open');

var series = gulp.series;
var parallel = gulp.parallel;

/* arguments */
var argv = require('minimist')(process.argv.slice(2), {
    string: ['path']
});

argv = extend({
    host: argv.host || 'localhost',
    port: argv.port || 9001,
    docHost: 'localhost',
    docPort: (argv.port || 9001) + 1,
    mockapi: argv.mockapi || false,
    teamcity: argv.teamcity || false
}, argv);


/* variables */
var clientPath = 'client';

/* Immediate solution for bundling npm packages */
var nodePath = 'node_modules';
var indexFileName = 'index.html';

var clientTmp = 'client/tmp';

var condorSrc = 'client/condor';
var condorIndexFile = 'client/index.html';
var signInIndexFile = 'dist/signin/index.html';
var signInSrc = 'client/signin';
var redirectSrc = 'client/redirect';
var redirectIndexFile = 'client/redirect/index.html';
var redirectDmsIndexFile = 'client/redirect/integration/index.html';
var batchEventSrc = 'client/batchEventUpdate';
var batchEventIndexFile = 'client/batchEventUpdate/index.html';

var condorNgTemp = clientTmp + '/ng';
var condorNgDist = 'dist/ng';
var condorDist = 'dist/condor';

var angularModule = 'inprotech';
var coveragePath = 'coverage';
var karmaConfigFile = path.join(__dirname, 'karma.conf.js');
var distPath = 'dist';
var scriptsPath = distPath + '/condor/kendo-intl';
var cachebust = new CacheBuster();
var debug = argv.debug;
var includeE2e = eval(argv.includeE2e);
var gzCompress = eval(argv.gzCompress);
var transpiledPath = condorSrc + '/transpiled';

var htmlminOptions = {
    collapseBooleanAttributes: false,
    collapseWhitespace: true,
    conservativeCollapse: true,
    removeAttributeQuotes: false,
    removeComments: true,
    removeEmptyAttributes: true,
    removeScriptTypeAttributes: true,
    removeStyleLinkTypeAttributes: true,
    keepClosingSlash: true
};

var assets = [];
//var assets1 = [];
var assetsBatchEvent = [];

var lint = {
    src: function(done) {
        var condorFiles = [condorSrc + '/**/*.js', '!' + condorSrc + '/**/*.spec.js', '!' + condorSrc + '/**/*.mock.js', '!' + condorSrc + '/mocks/**/*', '!' + condorSrc + '/transpiled/**/*.js'];
        //TODO: BatchEvent?      
        lint.src.displayName = "lint-src";
        return lintFn(done, '.eslintrc-src', condorFiles);
    },
    node: function(done) {
        return lintFn(done, '.eslintrc-node', ['server/**/*.js', 'gulpfile.js', 'karma.conf.js', 'build-helpers/**/*.js']);
    },
    ts: function(done) {
        if (argv.nolint) {
            done();
            return;
        }

        gulp.src(condorSrc + '/**/*.ts')
            .pipe(tslint({
                formatter: "prose",
                program: require('tslint').Linter.createProgram("./tsconfig.json")
            }))
            .pipe(tslint.report({
                emitError: true
            }));
        done();
    },
    ng: function(cb) {
        if (argv.nolint) {
            cb();
            return;
        }

        exec('npx ng lint lint-src && npx ng lint signinNg', function(err, stdout, stderr) {
            util.log(stdout);
            util.log(stderr);
            cb(err);
        });
    },
    test: function(done) {
        var condorFiles = [condorSrc + '/**/*.spec.js', condorSrc + '/**/*.mock.js', condorSrc + '/mocks/**/*', 'test.conf.js', '!' + condorSrc + '/transpiled/**/*.js'];
        return lintFn(done, '.eslintrc-test', condorFiles);
    },
    test_ng: function(cb) {
        if (argv.nolint) {
            cb();
            return;
        }

        exec('npx ng lint lint-spec && npx ng lint signinNg', function(err, stdout, stderr) {
            util.log(stdout);
            util.log(stderr);
            cb(err);
        });
    }
};

var clean = {
    rm: function(cb) {
        var target = getCommonDeployTarget();
        var command = 'npm run empty ' + target;
        util.log('Running ' + command);
        exec(command, function(err) {
            cb(err);
        });
    },
    delete: function(path, done) {
        return g.del(path, done);
    },
    karma: function(done) {
        return clean.delete(coveragePath, done);
    },
    tmp: function(done) {
        return clean.delete(clientTmp, done);
    },
    ts: function(done) {
        return clean.delete(transpiledPath, done);
    },
    dist: function(done) {
        return clean.delete(distPath, done);
    }
};

var deployment = {
    deploy: function(done) {
        return series(clean.rm, function deploy() {
            var target = getCommonDeployTarget();

            var deployTask = gulp.src(distPath + '/**/*')
                .pipe(gulp.dest(target));

            return deployTask;
        })(done);
    },
    symlink: function(done) {
        return series(createSymlink.clear, buildHybrid, createSymlink.create, createSymlink.watchSourceMaps)(done); // buildHybrid, 
    },
    vsdeploy: function(done) {
        return series(build, deployment.deploy)(done);
    },
    vsrelease: function(done) {
        argv.includeBatchEvent = true;
        argv.vsrelease = true;
        argv.gzCompress = true;

        return deployment.vsdeploy(done);
    }
};

var createSymlink = {
    clear: function(cb) {
        var clientFolder = '../Inprotech.Server/bin/Debug/client';
        if (fs.existsSync(clientFolder)) {
            util.log('Remove client folder');
            exec('npm run empty ' + clientFolder, function(err) {
                cb(err);
            });
        }
        cb();
    },
    create: function(cb) {
        var clientFolder = '../Inprotech.Server/bin/Debug/client';
        if (fs.existsSync(distPath)) {
            var linkDirectory = path.resolve(clientFolder);
            var targetDirectory = path.resolve(distPath);
            var linkCmd = 'mklink /D ' + linkDirectory + ' ' + targetDirectory;
            util.log('create symlink. cmd: ' + linkCmd);
            exec(linkCmd, function(err) {
                util.log('Inprotech app is now available at http://localhost/CPAInproma/apps/#/');
                cb(err);
            });
        }
        cb();
    },
    watchSourceMaps: function(done) {
        gulp.watch(distPath + '/ng', createSymlink.delSourceMaps);
        return series(createSymlink.delSourceMaps)(done);
    },
    delSourceMaps: function(done) {
        ng2.execute('npm run clearSourceMaps', done);
    }
};


var compileCss = {
    app: function() {
        var css = g.cssProcessor(g.dom({
            file: condorIndexFile,
            selector: 'link[rel="stylesheet"][data-concat!="false"]',
            attribute: 'href'
        }), assets);

        var sass = g.cssProcessor(gulp.src(condorSrc + '/app.scss').pipe(g.sass()), assets);

        return g.merge(css, sass)
            .pipe(g.concat('condor-app.css'))
            .pipe(g.cssmin())
            .pipe(g.rename({
                suffix: '.min'
            }))
            .pipe(cachebust.resources())
            .pipe(gulp.dest(distPath + '/styles'));
    },
    forServe: function() {
        return gulp.src(condorSrc + '/app.scss')
            .pipe(g.sourcemaps.init())
            .pipe(g.sass({
                sourceComments: true
            }))
            .pipe(g.concat('condor-app.css'))
            .pipe(g.sourcemaps.write().on('error', g.util.log))
            .pipe(gulp.dest(clientTmp + '/styles'));
    },
    forServe_signIn: function() {
        return gulp.src(signInSrc + '/src/styles.scss')
            .pipe(g.sourcemaps.init())
            .pipe(g.sass({
                sourceComments: true
            }))
            .pipe(g.concat('signin-app.css'))
            .pipe(g.sourcemaps.write().on('error', g.util.log))
            .pipe(gulp.dest(clientTmp + '/styles'));
    }
};

var batchEvent = {
    compile: {
        css: function() {
            var css = g.cssProcessor(g.dom({
                file: batchEventIndexFile,
                selector: 'link[rel="stylesheet"][data-concat!="false"]',
                attribute: 'href'
            }), assetsBatchEvent);

            return g.merge(css)
                .pipe(g.concat('batchevent-app.css'))
                .pipe(g.cssmin())
                .pipe(g.rename({
                    suffix: '.min'
                }))
                .pipe(cachebust.resources())
                .pipe(gulp.dest(distPath + '/batchEventUpdate'));
        },
        assets: function() {
            return gulp.src(assetsBatchEvent)
                .pipe(gulp.dest(distPath + '/batchEventUpdate/assets'));
        },
        js: {
            lib: function() {
                //uglify if not minified
                var onlyif = require('gulp-only');
                var isSource = onlyif(function(file) {
                    return !file.isMinified && /[.-]min./i.test(file.path) === false;
                });

                return g.jsMinSrc({
                    htmlFile: indexFileName,
                    cwd: batchEventSrc,
                    nmd: nodePath,
                    onlyExternalFiles: true
                })
                    .pipe(isSource(g.uglify()))
                    .pipe(g.concat('lib.min.js'))
                    .pipe(cachebust.resources())
                    .pipe(gulp.dest(distPath + '/batchEventUpdate'));
            },
            src: function() {
                return g.merge(g.includeJs.src(batchEventSrc, batchEventIndexFile, getIncludeJsConfigForBatchEvent()))
                    .pipe(g.if(debug, g.sourcemaps.init()))
                    .pipe(g.concat('app.min.js'))
                    .pipe(g.uglify())
                    .pipe(cachebust.resources())
                    .pipe(g.if(debug, g.sourcemaps.write('.').on('error', g.util.log)))
                    .pipe(gulp.dest(distPath + '/batchEventUpdate'));
            }
        },
        index: function(done) {
            return series(batchEvent.compile.js.lib, batchEvent.compile.js.src, batchEvent.compile.css, batchEvent.copy.customCss, batchEvent.compile.assets, function batch_index() {
                var htmlOptions = extend(htmlminOptions, {
                    removeScriptTypeAttributes: false,
                    removeComments: false
                })
                return gulp.src(batchEventIndexFile)
                    .pipe(g.cheerio(function($) {
                        $('link[rel="stylesheet"][data-concat!="false"]').remove();
                        $('script[data-concat!="false"][type!="text/html"]').remove();
                        $('body').append('<script src="lib.min.js"></script>');
                        $('body').append('<script src="app.min.js"></script>');
                        $('head').append('<link rel="stylesheet" href="batchevent-app.min.css">');
                        $('head').append('<link rel="stylesheet" href="custom.css">');
                        $('body').attr('ng-strict-di', '');
                    }))
                    .pipe(g.copyJsMinSrc(distPath + '/batchEventUpdate'))
                    .pipe(g.htmlmin(htmlOptions))
                    .pipe(cachebust.references())
                    .pipe(gulp.dest(distPath + '/batchEventUpdate'));
            })(done);
        }
    },
    copy: {
        customCss: function() {
            return gulp.src([batchEventSrc + '/custom.css'], {
                base: 'client'
            })
                .pipe(gulp.dest(distPath));
        },
        dateJsi18n: function() {
            return gulp.src([
                clientPath + '/batchEventUpdate/externaldependency/datejs/build/production/i18n/*.js'
            ], {
                base: 'client'
            })
                .pipe(g.rename({
                    dirname: ''
                }))
                .pipe(gulp.dest(distPath + '/batchEventUpdate/externaldependency/datejs/build/production/i18n'));
        }
    }
}

var ng2 = {
    execute: function(command, done) {
        util.log('Running ' + command);
        var bat = spawn('cmd.exe', ['/c', command], { stdio: 'inherit' });
        bat.on('exit', function(code) {
            if (code === 0) {
                done();
            }

        });
    },
    compile: {
        dev: function(done) {
            ng2.execute('npm run build:ng', done);
        },
        prod: function(done) {
            ng2.execute('npm run build:ng:prod', done);
        },
        prodCompress: function(done) {
            ng2.execute('npm run build:ng:prod:compressNg', done);
        },
        e2e: function(done) {
            ng2.execute('npm run build:ng:prod:e2e', done);
        }
    },
    devWatch: function(cb) {
        var started = false;
        var mainjsCount = 0;
        var bat = (argv.isHybrid) ? spawn('cmd.exe', ['/c', 'npm run build:ng:hybrid']) : spawn('cmd.exe', ['/c', 'npm run build:ng:watch']);
        bat.stdout.on('data', function(data) {
            var d = data.toString();
            util.log('\x1b[1m\x1b[33m%s\x1b[0m', d);
            if (!started && d.indexOf('(main)') >= 0) {
                mainjsCount++;
                if (mainjsCount > 1) {
                    started = true;
                    util.log('Started watch for Ng');
                    cb();
                }
            }
        });

        bat.stderr.on('data', function(data) {
            util.log(data.toString());
        });

        bat.on('exit', function(code) {
            util.log('Child exited with code ' + code);
        });

    },
    test: function(done) {
        var command = 'npx jest';

        if (argv.teamcity) {
            command += ' --verbose --ci';
            argv.jestworkers = argv.jestworkers || 2;
        }

        if (argv.jestworkers) {
            command += ' --maxWorkers=' + argv.jestworkers;
        }

        if (argv.coverage) {
            command += ' --coverage';
        }

        ng2.execute(command, done);
    }
};

var redirect = {
    compile: {
        js: {
            lib: function() {
                return g.jsMinSrc({
                    htmlFile: redirectIndexFile,
                    nmd: nodePath,
                    onlyExternalFiles: true
                })
                    .pipe(g.uglify())
                    .pipe(g.concat('libr.min.js'))
                    .pipe(cachebust.resources())
                    .pipe(gulp.dest(distPath + '/redirect'));
            },
            src: function() {
                return g.merge(g.includeJs.src(redirectSrc, getIncludeJsConfig()))
                    .pipe(g.if(debug, g.sourcemaps.init()))
                    .pipe(g.concat('appr.min.js'))
                    .pipe(g.ngAnnotate())
                    .pipe(g.uglify())
                    .pipe(cachebust.resources())
                    .pipe(g.if(debug, g.sourcemaps.write('.').on('error', g.util.log)))
                    .pipe(gulp.dest(distPath + '/redirect'));
            },
            integration: function() {
                return gulp.src(redirectDmsIndexFile).pipe(gulp.dest(distPath + '/redirect/integration'));
            }
        },
        index: function(done) {
            return series(redirect.compile.js.lib, redirect.compile.js.src, function redirect_index() {
                var redirectTask = gulp.src(redirectIndexFile)
                    .pipe(g.cheerio(function($) {
                        $('script[data-concat!="false"]').remove();
                        $('body').append('<script src="./libr.min.js"></script>');
                        $('body').append('<script src="./appr.min.js"></script>');
                        $('body').attr('ng-strict-di', '');
                    }))
                    .pipe(g.copyJsMinSrc(distPath + '/redirect'))
                    .pipe(g.htmlmin(htmlminOptions))
                    .pipe(cachebust.references())
                    .pipe(gulp.dest(distPath + '/redirect'));

                return redirectTask;
            }, redirect.compile.js.integration)(done);
        }
    }
};

var watch = {
    sass: function(done) {
        gulp.watch(condorSrc + '/**/*.scss', series(compileCss.forServe));
        gulp.watch('node_modules/designguide/**/*.scss', parallel(compileCss.forServe, compileCss.forServe_signIn));
        done();
    },
    ts: function(done) {
        gulp.watch(condorSrc + '/**/*.ts', ts_compile);
        done();
    }
}

var copy = {
    app: function() {
        return gulp.src([
            condorSrc + '/localisation/translations/**',
            clientPath + '/styles/custom.css',
            clientPath + '/favicon.*',
            clientPath + '/images/*.*',
            clientPath + '/robots.txt'
        ], {
            base: 'client'
        })
            .pipe(gulp.dest(distPath));
    },
    i18n: function() {
        return gulp.src([
            'node_modules/angular-i18n/angular-locale_**'
        ], {
            base: 'client'
        })
            .pipe(g.rename({
                dirname: ''
            }))
            .pipe(gulp.dest(distPath + '/condor/i18n'));
    },
    kendo_locales: function() {
        return gulp.src([
            'node_modules/@progress/kendo-angular-intl/locales/json/**/calendar.json',
            'node_modules/@progress/kendo-angular-intl/locales/json/**/numbers.json'
        ])
            .pipe(gulp.dest(distPath + '/condor/kendo-intl'));
    },
    cookie_declaration: function() {
        return gulp.src([
            clientPath + '/cookieDeclaration.html'
        ], {
            base: 'client'
        })
            .pipe(gulp.dest(distPath));
    }
};

var signIn = {
    compile: {
        index: function() {
            return gulp.src(signInIndexFile)
                .pipe(g.cheerio(function($) {
                    $('head').append('<link rel="stylesheet" href="../styles/custom.css">');
                }))
                .pipe(gulp.dest(distPath + '/signin'));
        }
    }
};

var app = {
    compile: {
        assets: function() {
            return gulp.src(assets)
                .pipe(gulp.dest(distPath + '/styles/assets'));
        },
        js: {
            lib: function() {
                //uglify if minified
                var onlyif = require('gulp-only');
                var isSource = onlyif(function(file) {
                    return !file.isMinified && /[.-]min./i.test(file.path) === false;
                });
                return g.jsMinSrc({
                    htmlFile: condorIndexFile,
                    nmd: nodePath
                })
                    .pipe(isSource(g.uglify()))
                    .pipe(g.concat('lib.min.js'))
                    .pipe(g.if(gzCompress, g.gzip()))
                    .pipe(cachebust.resources())
                    .pipe(gulp.dest(distPath + '/condor'));
            },
            src: function() {
                return g.merge(
                    g.includeJs.src(condorSrc, getIncludeJsConfig()),
                    compileTemplates())
                    .pipe(g.if(debug, g.sourcemaps.init()))
                    .pipe(g.concat('app.min.js'))
                    .pipe(g.ngAnnotate())
                    .pipe(g.uglify())
                    .pipe(g.if(gzCompress, g.gzip()))
                    .pipe(cachebust.resources())
                    .pipe(g.if(debug, g.sourcemaps.write('.').on('error', g.util.log)))
                    .pipe(gulp.dest(distPath + '/condor'));
            }
        },
        index: function(done) {
            return series(app.compile.js.lib, app.compile.js.src, compileCss.app, function app_index() {
                return gulp.src(condorIndexFile)
                    .pipe(g.cheerio(function($) {
                        $('link[rel="stylesheet"][data-concat!="false"]').remove();
                        $('script[data-concat!="false"]').remove();
                        $('title').after('<script>window.INPRO_DEBUG = ' + !!debug + ';</script>');
                        $('title').after('<script>window.INPRO_INCLUDE_E2E_PAGES = ' + includeE2e + ';</script>');
                        $('body').append(g.includeJs.getJs(condorDist, getIncludeJsConfig(), gzCompress));
                        $('body').append(g.includeNg.getNg(condorNgDist, gzCompress));
                        $('head').append('<link rel="stylesheet" href="styles/condor-app.min.css">');
                        $('head').append(function() {
                            return gulp.src('dist/*ng/*.css')
                                .pipe(g.tap(function(file) {
                                    var name = path.parse(file.path).name;
                                    return '<link rel="stylesheet" href="ng/' + name + '.css">';
                                }));
                        });
                        $('head').append('<link rel="stylesheet" href="styles/custom.css">');
                        $('body').attr('ng-strict-di', '');
                    }))
                    .pipe(g.copyJsMinSrc(distPath + '/condor'))
                    .pipe(g.htmlmin(htmlminOptions))
                    .pipe(cachebust.references())
                    .pipe(gulp.dest(distPath));
            })(done);
        },
        includeJs: function() {
            return gulp.src(condorIndexFile)
                .pipe(g.includeJs.convert(condorSrc, getIncludeJsConfig(), gzCompress))
                .pipe(g.includeNg.convert(condorNgTemp, getIncludeJsConfig()))
                .pipe(gulp.dest(clientTmp));
        }
    }
}


var initAllDisplayNames = function() {
    initDisplayNames(lint, 'lint');
    initDisplayNames(clean, 'clean');
    initDisplayNames(compileCss, 'compileCss');
    initDisplayNames(batchEvent, 'batchEvent');
    initDisplayNames(ng2, 'ng');
    initDisplayNames(redirect, 'redirect');
    initDisplayNames(watch, 'watch');
    initDisplayNames(copy, 'copy');
};
initAllDisplayNames();

/* tasks */

function test(done) {
    var cleanTasks = parallel(clean.karma, clean.tmp, clean.ts);
    var testTasks = [karma];
    var angularTestTasks = [ng2.test];
    var tscompileTask = [ts_compile];
    var combineTask = (argv.coverage) ? [combineCoverage] : [];

    if (argv.ngonly) {
        argv.nobuild = true;
        testTasks = [];
        tscompileTask = [];
    }
    if (argv.ngjsonly) {
        testTasks = karma;
        angularTestTasks = [];
    }

    if (argv.nobuild) {
        return series(parallel(clean.karma, clean.ts), angularTestTasks, tscompileTask, testTasks, combineTask)(done);
    }

    return series(cleanTasks, 'lint', parallel(lint.test_ng, lint.test), angularTestTasks, tscompileTask, ng2.compile.dev, app.compile.includeJs, testTasks, combineTask)(done);
}

function combineCoverage() {
    util.log('combine coverage reports');
    return exec('npm run combineCoverage', function(stdout, stderr) {
        util.log(stdout);
        util.log(stderr);
    });
}

function serve(done) {
    if (typeof debug === 'undefined') {
        debug = true;
        includeE2e = true;
    }

    if (argv.hybrid) {
        includeE2e = true;
        return series(deployment.symlink)(done);
    }

    var deps = [
        parallel([clean.ts, clean.tmp]),
        argv.nolint ? ng2.devWatch : parallel(['lint', ng2.devWatch]),
        ts_compile, parallel([compileCss.forServe, app.compile.includeJs]),
        compileCss.forServe_signIn,
        watch.sass,
        watch.ts
    ];

    if (!argv.realapi && !argv.mockapi) {
        deps.push(serve_mockapi);
    }

    deps.push(serve_nodeserver);

    return series(deps)(done);
}

function scan(done) {
    argv.scanTarget = getCommonDeployTarget();
    argv.includeBatchEvent = true;
    argv.scanOutput = 'retirejs-result.json';

    return series(deployment.vsdeploy, scan_vulnerable_packages)(done);
}

function build(done) {
    var cleanTasks = [clean.ts, clean.dist];
    var compileTasks = [ts_compile, redirect.compile.index, includeE2e ? ng2.compile.e2e : ng2.compile.prod];
    var compileIndexTasks = [app.compile.index, signIn.compile.index, app.compile.assets];
    var copyTasks = [copy.app, copy.i18n, copy.kendo_locales, copy.cookie_declaration];

    if (!argv.gzCompress) {
        compileTasks = compileTasks.concat(compileIndexTasks);
    } else {
        compileTasks.push(ng2.compile.prodCompress);
        compileTasks = compileTasks.concat(compileIndexTasks);
    }

    if (argv.includeBatchEvent) {
        compileTasks.push(batchEvent.compile.index);
        copyTasks.push(batchEvent.copy.dateJsi18n);
    }

    return series(cleanTasks, 'lint', compileTasks, copyTasks, MergeKendoScripts)(done);
}

function buildHybrid(done) {
    argv.isHybrid = true;
    debug = false;
    var cleanTasks = [clean.ts, clean.dist];
    var compileTasks = [ts_compile, redirect.compile.index, ng2.devWatch, app.compile.index, app.compile.assets];
    var copyTasks = [copy.app, copy.i18n, copy.kendo_locales, copy.cookie_declaration];

    var cleanAndLint = [cleanTasks];
    if (!argv.nolint) {
        cleanAndLint.push('lint');
    }

    return series(cleanAndLint, compileTasks, copyTasks, MergeKendoScripts)(done);
}

// 'security verification'
function scan_vulnerable_packages(done) {
    var output = path.join(__dirname, argv.scanOutput);
    var scanCommand = 'retire --path "' + argv.scanTarget + '" --outputformat json --outputpath "' + output + '" --severity low --exitwith 0';
    var child = exec(scanCommand, function() {
        done();
    });

    child.on('exit', function() {
        return g.retirejsOutput({
            jsonOutput: argv.scanOutput,
            cwd: __dirname
        });
    });
}

function serve_mockapi(done) {
    var server = g.liveserver('server/index.js', {
        env: {
            PORT: argv.port + 2
        }
    }, argv.port + 3);
    server.start();

    gulp.watch('server/**/*.js', function(cb) {
        server.start();
        cb();
    });
    done();
}

function serve_nodeserver(done) {
    var target = argv.client || clientPath;

    if (argv.dist) {
        target = distPath;
    }

    var baseDev = 'http://localhost/cpainproma/apps';
    var apiEndpoint;

    if (argv.realapi) {
        apiEndpoint = argv.realapi === true ? baseDev : argv.realapi;
    } else if (argv.mockapi && argv.mockapi !== true) {
        apiEndpoint = argv.mockapi;
    } else {
        apiEndpoint = 'http://' + argv.host + ':' + (argv.port + 2);
    }

    util.log('Api endpoint: ' + apiEndpoint);
    var settings = {
        port: argv.port,
        host: argv.host,
        livereload: argv.livereload || argv.lr || false,
        open: !argv.headless,
        directoryListing: false,
        fallback: condorIndexFile
    };

    if (target === clientPath) {
        settings.middleware = function() {
            return [function(req, res, next) {
                if (req.url === '/styles/condor-app.css') {
                    req.url = '/tmp/styles/condor-app.css';
                } else if (req.url === '/signin/styles/signin-app.css') {
                    req.url = '/tmp/styles/signin-app.css';
                } else if (req.url === '/' || req.url === '/index.html') {
                    req.url = '/tmp/index.html';
                } else if (req.url.indexOf('/signin/redirect') === 0) {
                    req.url = req.url.replace('/signin', '');
                } else if (req.url === '/signin/' || req.url === '/signin/index.html') {
                    req.url = '/tmp/signin/index.html';
                } else if (req.url.indexOf('/signin/') === 0) {
                    req.url = '/tmp' + req.url;
                } else if (req.url.indexOf('/assets/i18n/') === 0) {
                    util.log('assets  ' + req.url);
                }

                var fs = require('fs');
                var fileStream;

                if (req.url.indexOf("/condor/i18n") > -1) {
                    var n = 'node_modules/angular-i18n/' + req.url.match('[^/]*$')[0];
                    fileStream = fs.createReadStream(path.join(process.cwd(), n));
                    fileStream.pipe(res);
                    return;
                }

                if (req.url.indexOf("/condor/kendo-intl/") > -1) {
                    var kendoUrlString = "/condor/kendo-intl/";
                    var kendoUrlIdx = req.url.indexOf(kendoUrlString);
                    var allJsonIdx = req.url.indexOf("/all.json");
                    var locale = req.url.substring(kendoUrlIdx + kendoUrlString.length, allJsonIdx);
                    var urlPath = 'node_modules/@progress/kendo-angular-intl/locales/json/' + locale + '/all.json';
                    fileStream = fs.createReadStream(path.join(process.cwd(), urlPath));
                    fileStream.pipe(res);
                    return;
                }

                if (req.url.match(/^\/signalr*/)) {
                    res.end();
                    return;
                }

                if ((req.url.indexOf('batchEventUpdate/node_modules') >= 0) || (req.url.indexOf('node_modules') <= 0)) {
                    req.url = '/' + clientPath + req.url
                }
                next();
            }, g.proxy('/api', {
                target: apiEndpoint
            })]
        };
    }
    g.connect.server(settings, function() {
        if (settings.open) {
            g.open('http://' + settings.host + ':' + settings.port);
        }
        done();
    });
}

/* internal tasks */

function ts_compile(cb) {
    exec('"' + __dirname + '/node_modules/.bin/tsc" --project "' + __dirname + '/tsconfig.json"', function(err, stdout, stderr) {
        util.log(stdout);
        util.log(stderr);
        cb(err);
    });
}

// Not Used
gulp.task('copy:index-SignIn', function() {
    return gulp.src([
        clientPath + '/signin/index.html',
        clientPath + '/signin/redirect/index.html'
    ], {
        base: 'client'
    })
        .pipe(gulp.dest(clientTmp));
});
gulp.task('compile:js:ng-Signin:prod', function() {
    return exec('npm run build:signinng:prod', function(err, stdout, stderr) {
        util.log(stdout);
        util.log(stderr);
    });
});

function getFolders(dir) {
    return fs.readdirSync(dir)
        .filter(function(file) {
            return fs.statSync(path.join(dir, file)).isDirectory();
        });
}

function MergeKendoScripts(done) {
    var folders = getFolders(scriptsPath);
    if (folders.length === 0) return done(); // nothing to do!
    var tasks = folders.map(function(folder) {
        return gulp.src(path.join(scriptsPath, folder, '/**/*.json'))
            // concat into all.json
            .pipe(g.jsonMerge({
                fileName: 'all.json'
            }))
            // write to output
            .pipe(gulp.dest(path.join(scriptsPath, folder)))
    });

    return g.mergeStream(tasks);
}

function karma(done) {
    var server = new g.karma.Server({
        configFile: karmaConfigFile
    }, function(result) {
        g.util.log('Check coverage report in "coverage".');
        done(result === 0 ? 0 : {
            showStack: false,
            toString: function() {
                return 'Error running tests!';
            }
        });
    });

    server.start();
}

/* helpers */

function isFunction(obj) {
    return !!(obj && obj.constructor && obj.call && obj.apply);
}

function task(description, task, flags) {
    task.description = description;
    task.flags = flags;
    return task;
}

function initDisplayNames(obj, prefix) {
    var keys = Object.keys(obj);

    for (var i = 0; i < keys.length; i++) {
        var p = obj[keys[i]];
        if (isFunction(p)) {
            p.displayName = prefix + ':' + p.name;
        } else if (typeof p === 'object') {
            initDisplayNames(p, prefix + ':' + keys[i]);
        }
    }
}

function lintFn(done, configFile, jsFiles) {
    if (argv.nolint) {
        return done();
    }

    if (fs.existsSync(clientPath + '/bower_components')) {
        throw new util.PluginError({
            plugin: 'lint',
            message: '[Error]: ' + clientPath + '/bower_components folder exists, please remove the folder.'
        });
    }

    return gulp.src(jsFiles.concat('!**/transpiled/*'))
        .pipe(g.eslint(configFile))
        .pipe(g.eslint.format())
        .pipe(g.eslint.failAfterError());
}

function compileTemplates() {
    var defaultNgTemplateMinifierOptions = {
        removeComments: true,
        collapseWhitespace: true,
        preserveLineBreaks: false,
        conservativeCollapse: false
    };

    return gulp.src([condorSrc + '/**/*.html'])
        .pipe(g.htmlmin(htmlminOptions))
        .pipe(g.ngTemplates({
            module: angularModule,
            standalone: false,
            path: function(filePath, base) {
                var result = path.join(path.basename(base), filePath.slice(base.length).replace(/\\/g, '/'));
                return result;
            },
            htmlMinifier: Object.assign(defaultNgTemplateMinifierOptions, {
                keepClosingSlash: true,
                conservativeCollapse: true,
                collapseBooleanAttributes: false,
                collapseInlineTagWhitespace: false
            })
        }));
}

//defer importing modules
function define(target, propName, moduleName) {
    var module;
    moduleName = moduleName || propName;

    Object.defineProperty(target, propName, {
        get: function() {
            if (module) {
                return module;
            }

            module = require(moduleName);

            return module;
        }
    });
}

function getIncludeJsConfig() {
    if (debug) {
        return {}; // don't filter out any files
    }

    return {
        filter: function(fileUrl) {
            var f = fileUrl.replace(/\\/g, '/');

            var filterOutDevPages = f.indexOf(condorSrc + '/dev/') === -1;
            var filterOutE2ePages = f.indexOf(condorSrc + '/dev-e2e/') === -1;

            return includeE2e ? filterOutDevPages : filterOutDevPages && filterOutE2ePages;
        }
    };
}

function getIncludeJsConfigForBatchEvent() {
    return {
        filter: function(fileUrl) {
            var f = fileUrl.replace(/\\/g, '/');

            var filterOutNodeModules = f.indexOf(batchEventSrc + '/node_modules/') === -1;

            return filterOutNodeModules;
        }
    };
}

function getCommonDeployTarget() {
    var target;
    if (argv.vsdebug) {
        target = '../Inprotech.Server/bin/Debug/client';
    } else if (argv.vsrelease) {
        target = '../Inprotech.Server/bin/Release/client';
    } else {
        target = argv.path;
    }

    return target || '../Inprotech.Server/bin/Debug/client';
}

exports.lint = task('Checks all .js files for errors and potential problems.', parallel(lint.ts, lint.src, lint.node, lint.ng));
exports.serve = task('Serves the site with node server', serve, {
    'realapi': 'Use the configured real API server. 1. argument value 2. serve-proxies.json',
    'mockapi': 'Use the configured mock API server. 1. argument value 2. serve-proxies.json',
    'client': 'The root path of client files for serving.',
    'dist': 'Serve ./dist instead of working directory.',
    'headless': 'Dont open a browser window',
    'livereload': 'Enable live reload',
    'lr': 'Enable live reload',
    'hybrid': 'hybrid'
});
exports.test = task('Runs all unit tests', test, {
    'debug': 'Disable coverage report and single-run, and run in Chrome.',
    'dist': 'Test against dist folder.',
    'livereload': 'Disable single-run',
    'lr': 'Disable single-run',
    'dots': 'Enables dot reporter rather than spec reporter',
    'nobuild': 'Runs js test without rebuilding client code',
    'ngonly': 'Runs without angularJS',
    'jestworkers': 'Number of jest worker threads to use, default is process count - 1',
    'teamcity': 'sets the test reporters to Teamcity, if jest worker option is not provided, sets it to 2'
});
exports.vsrelease = task('Creates and deploys as release build', deployment.vsrelease, {
    'includeBatchEvent': 'Build and Deploy Batch Event',
    'gzCompress': 'Gzip compress ng2 and condor build files'
});
exports.vsdeploy = task('Creates and deploys as debug build', deployment.vsdeploy, {
    'includeBatchEvent': 'Build and Deploy Batch Event',
    'gzCompress': 'Gzip compress ng2 and condor build files'
});
exports.deploy = task('Deploys ./dist folder', deployment.deploy, {
    'path': 'Path to deploy to',
    'vsdebug': 'Copy to Inprotech.Server Debug folder',
    'vsrelease': 'Copy to Inprotech.Server Release folder'
});
exports.build = task('Creates a build of the app in ./dist', build, {
    'debug': 'Create source maps to aid debugging',
    'includeE2e=true/false': 'By default false. Set to true for including dev pages',
    'includeBatchEvent': 'Batch Event Update not included. Select to include',
    'gzCompress': 'Gzip compress ng2 and condor build files'
});

exports.clean = task('Cleans the ./dist folder', clean.dist);
exports.clean_rm = task('Cleans the deploy folder', clean.rm);
exports.scan = task('Scans for security vulnerability in 3rd party packages', scan, {
    'path': 'Specify explicit Path to deploy to, to override other deploy destination options'
});
exports.combineCoverage = task('combine', combineCoverage);