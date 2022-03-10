$(function () {
    $('#message-panel-close').blur(function () {
        $('#message-panel').hide();
    });

    $('#message-panel-close').click(function () {
        $('#message-panel').hide();
    });

    $(document).ajaxSend(function (event, xhr, options) {
        $('#spinner').show();
    });

    $(document).ajaxComplete(function (event, xhr, options) {
        $('#spinner').hide();

        var f = xhr.feedback;
        if (f) {
            var p = $('#message-panel');
            var b = $('#message-body');
            var c = $('#message-panel-close');
            var d = $('#messages-list');

            d.find('li').remove();

            b.text(f.message || "");

            if (typeof f.messageslist !== "undefined") {
                $.each(f.messageslist, function (index, message) {
                    d.append("<li>" + message + "</li>");
                });
            }

            if (f.isError)
                p.addClass('alert-error');
            else
                p.addClass('alert-success');

            xhr.feedback = null;
            p.show();

            if (!f.isError) c.focus();
        }
    });
});