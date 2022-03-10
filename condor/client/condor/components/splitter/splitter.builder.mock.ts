'use strict';

class SplitterBuilderMock implements ISplitterBuilder {
    public returnValues: any;

    constructor() {
        this.returnValues = {};
        spyOn(this, 'BuildOptions').and.callThrough();
    }

    BuildOptions = () => {
        return this.returnValues['BuildOptions'];
    };

    SetReturnValue = (property: string, value: any) => {
        this.returnValues[property] = value;
    };
}

angular.module('inprotech.mocks')
    .service('splitterBuilderMock', SplitterBuilderMock);
