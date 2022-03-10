angular.module('inprotech.processing.policing')
    .service('policingRequestAffectedCasesService', function (messageBroker, scheduler) {



        var receiveStatusUpdate = function (requestId, callback) {
            var topicStatus = 'policing.affected.cases.' + requestId;
            messageBroker.disconnect();

            messageBroker.subscribe(topicStatus, function (data) {
                scheduler.runOutsideZone(function () {
                    if (callback) {
                        callback(data);
                    }
                });
            });

            messageBroker.connect();

        };

        var disconnect = function () {
            messageBroker.disconnect();
        }

        return {
            getAffectedCases: function (requestId) {
                var callback;
                receiveStatusUpdate(requestId, function (resp) {
                    disconnect();
                    var data = {
                        data: {
                            noOfCases: resp.noOfCases,
                            isSupported: resp.isSupported
                        }
                    };
                    if (callback) {
                        return callback(data);
                    }
                });

                return {
                    then: function (cb) {
                        callback = cb;
                    }
                }
            }
        }
    });