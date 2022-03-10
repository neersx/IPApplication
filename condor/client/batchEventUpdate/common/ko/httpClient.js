var httpClient = (function () {
    'use strict';
    var defaultErrorHandler = function (xhr, status, errorThrown) {
        var okButton = application.toolbarButtonViewModel('OK', {
            dataAttributes: [{
                key: "data-dismiss",
                value: 'modal'
            }],
            isDefault: true
        });

        var errorMsg = xhr.status === 0 ? localise.getString('xhrLostConnection') : errorThrown;
        var m = {
            title: localise.getString('errorHeading'),
            message: errorMsg || localise.getString('unknownError'),
            type: 'error',
            buttons: [okButton]
        };
        ko.postbox.publish(application.messages.showDialog, m);
    };

    var onSessionTimeout = function (returnUrl) {
        var okText = localise.getString('btnOk');
        var cancelText = localise.getString('btnCancel');

        var okButton = application.toolbarButtonViewModel(okText, {
            dataAttributes: null,
            isDefault: true,
            clicked: function () {
                parent.location.reload();
            }
        });

        var cancelButton = application.toolbarButtonViewModel(cancelText, {
            dataAttributes: [{
                key: 'data-dismiss',
                value: 'modal'
            }],
            clicked: null
        });

        var m = {
            title: localise.getString('errorHeading'),
            message: localise.getString('errorSessionExpired'),
            type: 'error',
            buttons: [okButton, cancelButton]
        };

        ko.postbox.publish(application.messages.showDialog, m);
    };

    var removeEnrichmentFromResponse = function (response) {
        if (response && response.result) {
            response = response.result;
        }
        return response;
    };

    var getApplicationDetail = function (response) {
        var applicationDetail = {
            currentUser: response.intendedFor,
            systemInfo: response.systemInfo
        };

        return applicationDetail;
    };


    var handleUnauthorizedError = function () {
        window.location = utilities.appBaseUrl('signin?goto=' + encodeURIComponent(window.location));
    };

    var handleError = function (xhr, status, errorThrown, errorHandler) {
        if (xhr.status === 401)
            handleUnauthorizedError();

        if (!errorHandler) {
            defaultErrorHandler(xhr, status, errorThrown);
            return;
        }


        if (errorHandler(xhr, status, errorThrown))
            return;

        defaultErrorHandler(xhr, status, errorThrown);
    };

    function cookie(name) {
        var nameEQ = name + '=';
        var ca = document.cookie.split(';');
        for (var i = 0; i < ca.length; i++) {
            var c = ca[i];
            while (c.charAt(0) === ' ') {
                c = c.substring(1, c.length);
            }
            if (c.indexOf(nameEQ) === 0) {
                return c.substring(nameEQ.length, c.length);
            }
        }
        return null;
    }

    function appendAntiForgeryToken(request) {
        var xsrfToken = cookie('XSRF-TOKEN');

        if (xsrfToken !== null) {
            request.headers = {
                'X-XSRF-TOKEN': xsrfToken
            };
        }
        return request;
    }

    return {
        json: function (url, func, errorHandler) {
            $.getJSON(utilities.api(url), function (data) {

                if (data !== undefined) {
                    ko.postbox.publish('applicationDetail', getApplicationDetail(data));
                    data = removeEnrichmentFromResponse(data);
                }

                if (data !== undefined && data.SessionExpired) {
                    onSessionTimeout(data.ReturnUrl);
                } else {
                    func(data);
                }
            })
                .catch(function (xhr, status, errorThrown) {
                    handleError(xhr, status, errorThrown, errorHandler);
                });
        },
        postJson: function (url, data, callbacks) {
            callbacks = callbacks || {};
            var request = {
                url: utilities.api(url),
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function (response, status, xhr) {

                    var r = typeof response === 'string' ? JSON.parse(response) : response;

                    if (r) {
                        ko.postbox.publish('applicationDetail', getApplicationDetail(r));
                        response = removeEnrichmentFromResponse(r);
                    }

                    if (r && r.SessionExpired) {
                        onSessionTimeout(r.ReturnUrl);
                    } else {
                        if (!callbacks.success)
                            return;
                        xhr.feedback = callbacks.success(response, status, xhr);
                    }
                },
                error: function (xhr, status, errorThrown) {
                    handleError(xhr, status, errorThrown, callbacks.error);
                },
                complete: function () {
                    if (callbacks.complete)
                        callbacks.complete();
                }
            };

            $.ajax(appendAntiForgeryToken(request));
        }
    };

}());