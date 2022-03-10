var utils = function (my) {
    'use strict';
    my.httpStatusCode = {
        ok: 200,
        ambiguous: 300,
        internalServerError: 500
     };
    return my;
}(utils || {});