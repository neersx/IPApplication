angular.module('inprotech.core')
    .service('messageBroker', function (utils, scheduler) {
        'use strict';
        var log = utils.debug;

        var _bindings = {},
            _connection;

        this.subscribe = function (binding, callback) {
            if (!binding) {
                throw 'binding cannot be null';
            }

            _bindings[binding] = callback;
        };

        this.connect = function () {
            scheduler.runOutsideZone(connectInternal);
        }

        function connectInternal() {
            var connection = $.hubConnection();
            _connection = connection;

            connection.url = 'signalr';

            var bindings = _.keys(_bindings).join(',');
            connection.qs = {
                bindings: bindings
            };

            var proxy = connection.createHubProxy('messageBroker');

            proxy.on('receive', function (binding, data) {
                scheduler.runOutsideZone(function () {
                    log('RECEIVED. arguments=', JSON.stringify(arguments));

                    if (_bindings[binding]) {
                        _bindings[binding](data);
                    }
                });
            });

            log('CONNECTING. hub=messageBroker; bindings=', bindings);

            connection.disconnected(function () {
                scheduler.runOutsideZone(function () {
                    if (connection.lastError) {
                        log('DISCONNECTED. errors=', connection.lastError.message);
                    } else {
                        log('DISCONNECTED');
                    }
                });
            }
            );

            connection.reconnecting(function () {
                scheduler.runOutsideZone(function () {
                    log('RECONNECTING');
                });
            });

            connection.reconnected(function () {
                scheduler.runOutsideZone(function () {
                    log('RECONNECTED');
                });
            });

            return connection.start({ transport: ['webSockets', 'serverSentEvents', 'longPolling'] })
                .done(function () {
                    scheduler.runOutsideZone(function () {
                        log('CONNECTED. connection_id=', connection.id);
                    });
                })
                .fail(function () {
                    scheduler.runOutsideZone(function () {
                        log('CONNECTION FAILED');
                    });
                });
        }

        this.disconnect = function () {
            if (!_connection) {
                return;
            }

            log('DISCONNECTING');

            _connection.stop();

            _bindings = {};
            _connection = null;
        };
    });
