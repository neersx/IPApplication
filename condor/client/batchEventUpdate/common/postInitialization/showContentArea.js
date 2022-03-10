var postInitialization = function(my) {
    my.showContent = function() {
        $('#content').show();
    };

    return my;
}(postInitialization || {});