ko.bindingHandlers.translate = {
    update: function(element, valueAccessor, allBindings) {
        'use strict';

        if (!localise || !localise.loaded()) {
            return;
        }

        $(element).text(localise.getString(valueAccessor()));
    }
};

ko.bindingHandlers.translateOptionsCaption = {
    update: function(element, valueAccessor, allBindings) {
        'use strict';

        if (!localise || !localise.loaded()) {
            return;
        }

        var optionsCaptions = allBindings().optionsCaption;
        if (!optionsCaptions) {
            return;
        }

        $('option:first', $(element)).text(localise.getString(valueAccessor()));
        allBindings().optionsCaption = localise.getString(valueAccessor());
    }
};

ko.bindingHandlers.translateTooltip = {
    update: function(element, valueAccessor, allBindings) {
        'use strict';

        if (!localise || !localise.loaded()) {
            return;
        }

        if (typeof valueAccessor() === 'object') {
            $(element).prop('title', localise.getString(valueAccessor().id, valueAccessor().args));
            return;
        }

        $(element).prop('title', localise.getString(valueAccessor()));
    }
};
