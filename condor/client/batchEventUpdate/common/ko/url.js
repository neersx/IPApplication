var utils = function(my) {
    my.url = {
        params: function() {
            var params = {};
            var q = document.URL.split('?')[1];
            if (q !== undefined) {
                q = q.split('&');
                for (var i = 0; i < q.length; i++) {
                    var hash = q[i].split('=');
                    params[hash[0].toLowerCase()] =  decodeURIComponent(hash[1]);
                }
            }

            return params;
        }          
    };
    return my;
}(utils || {});