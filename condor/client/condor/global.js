$(function() {
    'use strict';

    //shortcut for primary action button in modal
    $(document).on('keydown', function(evt) {
        if (evt.which === 13) {
            var footer = $('.modal-dialog .modal-footer').eq(0);

            if (footer.length) {
                var btn = footer.find('.btn');
                var discard = footer.find('.btn-discard');
                var primary = footer.find('.btn-primary');

                if (btn.size() === 1) {
                    btn.click();
                } else if (primary.size() === 1) {
                    primary.click();
                } else if (discard.size() === 1) {
                    discard.click();
                }
            }
        }
    });
});
