import * as _ from 'underscore';

export class NameFilteredPicklistScope {
    isFilterByNameType: Boolean;
    filterNameType: String;
    nameTypeDescription: String;
    includeCeasedNames: Boolean;
    extendQuery: Function;

    constructor(filterNameType: String = null, nameTypeDescription: String = null, includeCeasedNames = false) {
        this.isFilterByNameType = true;
        this.filterNameType = filterNameType;
        this.nameTypeDescription = nameTypeDescription;
        this.extendQuery = this.extendNamePickList;
        this.includeCeasedNames = includeCeasedNames;
    }

    extendNamePickList = (query) => {
        if (this.filterNameType && this.isFilterByNameType) {
            return _.extend({}, query, {
                filterNameType: this.filterNameType,
                showCeased: this.includeCeasedNames
            });
        }

        if (!this.isFilterByNameType || this.filterNameType == null || this.includeCeasedNames) {
            return _.extend({}, query, {
                showCeased: this.includeCeasedNames
            });
        }

        return query;
    };
}
