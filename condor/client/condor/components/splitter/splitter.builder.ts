'use strict';

class SplitterDetails {
    id: string;
    options: kendo.ui.SplitterOptions;
    resize = (): void => { };
    resizePanesHeight = (): void => { };
    resizePane = (paneId: string, widthPer: string): void => { };
    togglePane = (paneId: string, collapse: boolean): void => { };

    constructor(id: string, options: kendo.ui.SplitterOptions) {
        this.id = id;
        this.options = options;
    }
}

interface ISplitterBuilder {
    BuildOptions(id: string, options: kendo.ui.SplitterOptions): SplitterDetails;
}

class SplitterBuilder implements ISplitterBuilder {
    defaultOptions: kendo.ui.SplitterOptions;

    constructor() {
        this.defaultOptions = {
            orientation: 'horizontal',
            panes: []
        }
    }

    public BuildOptions = (id: string, options: kendo.ui.SplitterOptions): SplitterDetails => {
        let result = new SplitterDetails(id, angular.merge({}, options, this.defaultOptions));
        result.resize = this.resizeMethod(id);
        result.resizePanesHeight = this.resizePanesHeightMethod(id);
        result.resizePane = this.resizePaneMethod(id);
        result.togglePane = this.togglePaneMethod(id);
        return result;
    }

    resizeMethod = (id: string): () => void => {
        return function () {
            let splitterElement = $('#' + id),
                splitterObject = splitterElement.data('kendoSplitter');
            splitterObject.resize(true);
        }
    }

    resizePanesHeightMethod = (id: string): () => void => {
        return function () {
            let splitterElement = $('#' + id);

            if (splitterElement.find('.k-pane div')[0] !== undefined) {
                splitterElement.height(splitterElement.find('.k-pane div')[0].scrollHeight);
            }
            splitterElement.data('kendoSplitter').trigger('resize');
        }
    }

    resizePaneMethod = (id: string): (paneId: string, widthPer: string) => void => {
        return function (paneId: string, widthPer: string) {
            let splitterElement = $('#' + id),
                splitterObject = splitterElement.data('kendoSplitter');
            splitterObject.size('#' + paneId, widthPer);
            splitterObject.resize();
        }
    }

    togglePaneMethod = (id: string): (paneId: string, collapse: boolean) => void => {
        return function (paneId: string, collapse: boolean) {
            let splitterElement = $('#' + id),
                splitterObject = splitterElement.data('kendoSplitter');

            if (splitterObject) {
                if (collapse) {
                    splitterObject.collapse('#' + paneId);
                } else {
                    splitterObject.expand('#' + paneId);
                }
            }
        }
    }
}

angular.module('inprotech.components.splitter')
    .service('splitterBuilder', () => new SplitterBuilder());
