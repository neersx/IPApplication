var postInitialization = function(my) {
    my.adjustWorkArea = function() {
        var workAreaAdjustment = function() {
            var container = $('.work-area-container');
            var navbar = $('.navbar-fixed-top');
            var toolbar = $('.work-area-container > .work-area > .toolbar');
            var header = $('.work-area-container > .work-area > .header');
            var body = $('.work-area-container > .work-area > .body');
            var headerTitle = $('.headerTitle');

            var interval = 500;
            var scrollbarOffset = 40;
            var toolbarOffset = 30;

            var offset = function() {
                return (navbar.length == 0 ? 0 : navbar.height()) +
                    (toolbar.length == 0 ? toolbarOffset : toolbar.height()) +
                    (header.length == 0 ? 0 : header.height()) +
                    (headerTitle.length==0? 0 : headerTitle.height())+
                    scrollbarOffset;
            };

            var lastSeenOffset = offset();

            var resize = function() {
                var o = offset();
                if (lastSeenOffset != o) {
                    body.height(container.height() - o);
                    lastSeenOffset = o;
                }
            };

            var setBodyHeight = function() {
                body.height(container.height() - offset());
            };

            var onTimer = function() {
                resize();
                setTimeout(onTimer, interval);
            };

            var listenToMutations = function(Observer) {
                var observer = new Observer(function() {
                    resize();
                });

                var config = {
                    subtree: true,
                    childList: true
                };

                if (navbar.length != 0)
                    observer.observe(navbar[0], config);

                if (toolbar.length != 0)
                    observer.observe(toolbar[0], config);

                if (header.length != 0)
                    observer.observe(header[0], config);
            };

            var pollForDomChanages = function() {
                setTimeout(onTimer, interval);
            };

            MutationObserver = window.MutationObserver || window.WebKitMutationObserver;

            if (!MutationObserver) {
                pollForDomChanages();
            } else {
                listenToMutations(MutationObserver);
            }

            $(window).resize(function() {
                setBodyHeight();
            });

            setBodyHeight();
        };

        workAreaAdjustment();       
    };

    return my;
}(postInitialization || {});