//jqAuto -- main binding (should contain additional options to pass to autocomplete)
//jqAutoSource -- the array of choices
//jqAutoValue -- where to write the selected value
//jqAutoSourceLabel -- the property that should be displayed in the possible choices
//jqAutoSourceInputValue -- the property that should be displayed in the input box
//jqAutoSourceValue -- the property to use for the value
//jqAutoSourceUserCode -- the property to use for the shortcut user-code for a particular value
ko.bindingHandlers.jqAuto = {
    init: function (element, valueAccessor, allBindingsAccessor, viewModel) {
        var options = valueAccessor() || {},
            allBindings = allBindingsAccessor(),
            unwrap = ko.utils.unwrapObservable,
            modelValue = allBindings.jqAutoValue,
            source = allBindings.jqAutoSource,
            query = allBindings.jqAutoQuery,
            valueProp = allBindings.jqAutoSourceValue,
            inputValueProp = allBindings.jqAutoSourceInputValue || valueProp,
            labelProp = allBindings.jqAutoSourceLabel || inputValueProp,
            userCodeValue = unwrap(allBindings.jqAutoSourceUserCode) || '';

        //function that is shared by both select and change event handlers 
        function writeValueToModel(valueToWrite) {
            if (ko.isWriteableObservable(modelValue)) {
                modelValue(valueToWrite);
            } else {  //write to non-observable 
                if (allBindings['_ko_property_writers'] && allBindings['_ko_property_writers']['jqAutoValue'])
                    allBindings['_ko_property_writers']['jqAutoValue'](valueToWrite);
            }
        }

        //on a selection write the proper value to the model 
        options.select = function (event, ui) {
            writeValueToModel(ui.item ? ui.item.actualValue : null);
        };

        var findMatchingItem = function (value) {
            if (value === "")
                return null;
            
            var matchingItem = ko.utils.arrayFirst(unwrap(source), function(item) {
                return unwrap(item[userCodeValue]) && unwrap(item[userCodeValue]).toUpperCase() === value.toUpperCase();
            });

            if (!matchingItem) {
                matchingItem = ko.utils.arrayFirst(unwrap(source), function(item) {
                    return unwrap(inputValueProp ? item[inputValueProp] : item).toUpperCase().indexOf((value.toUpperCase())) != -1;
                });
            }

            return matchingItem;
        };

        options.open = function () {
            // select none
            var highlightedItem = jQuery($('.ui-menu').find('li').find('.ui-state-hover')[0]);
            var selectedElementId = "ui-active-menuitem";
            if (highlightedItem.length > 0) {
                selectedElementId = highlightedItem.attr("id");
                highlightedItem.attr("id", null);
                highlightedItem.removeClass("ui-state-hover");
            }

            // select the selected one.
            var itemToHighlight = jQuery($("ul li a").filter(function () { return $(this).text() === $(element).val(); }));
            itemToHighlight.attr("id", selectedElementId);
            itemToHighlight.addClass("ui-state-hover");
            $(element).focus();
        };

        //hold the autocomplete current response 
        var currentResponse = null;

        //handle the choices being updated in mappedSource, to decouple value updates from source (options) updates 
        var mappedSource = ko.computed({
            read: function () {
                var mapped = ko.utils.arrayMap(unwrap(source), function (item) {
                    var result = {};
                    result.label = labelProp ? unwrap(item[labelProp]) : unwrap(item).toString();  //show in pop-up choices 
                    result.value = inputValueProp ? unwrap(item[inputValueProp]) : unwrap(item).toString();  //show in input box 
                    result.actualValue = valueProp ? unwrap(item[valueProp]) : item;  //store in model 
                    return result;
                });
                return mapped;
            },
            write: function (newValue) {
                source(newValue);  //update the source observableArray, so our mapped value (above) is correct 
                if (currentResponse) {
                    currentResponse(mappedSource());
                }
            },
            disposeWhenNodeIsRemoved: element
        });

        if (query) {
            options.source = function (request, response) {
                currentResponse = response;
                query.call(this, request.term, mappedSource);
            };
        } else {
            //whenever the items that make up the source are updated, make sure that autocomplete knows it 
            mappedSource.subscribe(function (newValue) {
                $(element).autocomplete("option", "source", newValue);
            });

            options.source = mappedSource();
        }

        var dropDownButton = $(element).siblings().data("data-dropdown", "autocomplete");
        if (dropDownButton) {
            dropDownButton.attr("TabIndex", "-1");
            dropDownButton.click(function () {
                // close if already visible
                if ($(element).autocomplete("widget").is(":visible")) {
                    $(element).autocomplete("close");
                    return;
                }
                $(element).autocomplete("search", "");
            });
        }
        
        $(element).blur(function () {
            var matchingItem = findMatchingItem($(element).val());

            if (matchingItem) {
                writeValueToModel(unwrap(matchingItem[valueProp]));
                $(element).val(unwrap(matchingItem[inputValueProp]));
            } else {
                writeValueToModel(null);
                $(element).val(null);
            }
        });

        //initialize autocomplete 
        $(element).autocomplete(options);
    },
    update: function (element, valueAccessor, allBindingsAccessor, viewModel) {
        //update value based on a model change 
        var allBindings = allBindingsAccessor(),
            unwrap = ko.utils.unwrapObservable,
            modelValue = unwrap(allBindings.jqAutoValue) || '', // the id set into the model
            valueProp = allBindings.jqAutoSourceValue, // the item id
            inputValueProp = allBindings.jqAutoSourceInputValue || valueProp; // the selected value displayed in the field

        //if we are writing a different property to the input than we are writing to the model, then locate the object 
        if (valueProp && inputValueProp !== valueProp) {
            var source = unwrap(allBindings.jqAutoSource) || [];
            modelValue = ko.utils.arrayFirst(source, function (item) {
                return unwrap(item[valueProp]) === modelValue;
            }) || {};
        }

        //update the element with the value that should be shown in the input 
        var newValue = (modelValue && inputValueProp !== valueProp) ? unwrap(modelValue[inputValueProp]) : modelValue.toString();
        if (newValue || newValue === 0) {
            $(element).val(newValue);
        } else {
            $(element).val(null);
        }
    }
};