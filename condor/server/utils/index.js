'use strict';
var fs = require('fs');
var path = require('path');
var _ = require('underscore');
var moment = require('moment');

exports.readJson = function(path, cb) {
    fs.readFile(path, function(err, str) {
        if (err) {
            throw err;
        }

        cb(JSON.parse(str));
    });
};

exports.parseQueryParams = function(params) {
    if (!params) {
        return {};
    }

    return JSON.parse(params);
};

exports.sortAndPaginate = function(data, params) {
    if (!params || !data.length) {
        return data;
    }
    params = JSON.parse(params);
    data = sort(data, params);
    data = paginate(data, params);
    return data;
};

exports.readColumnData = function(gridResultsPath, column, cb) {
    this.readJson(gridResultsPath, function(data) {
        cb(getColumnValues(data, column));
    });
};

exports.readColumnFilter = function(all, column, filters) {
    var queryParams = {
        filters: null
    };
    var f=JSON.parse(filters)
    if (f.length > 0) {
        queryParams.filters = f;
    }

    all = this.filterGridResults(all, JSON.stringify(queryParams));
    var map = all.map(function(item) {
        return {
            code: item[column],
            description: item[column]
        };
    });
    return _.sortBy(_.unique(map, function(item) {
        return item.code;
    }), function(item) {
        return item.description || null;
    });
};

exports.filterGridResultsOnCodeProperty = function(all, queryParams) {
    return filter(all, queryParams, getWhereClausesForCodeProperty);
}
exports.filterGridResults = function(all, queryParams) {
    return filter(all, queryParams, getWhereClauses);
};

exports.enrich = function(r) {
    var defaultEnrichment = JSON.parse(fs.readFileSync(path.join(__dirname, '../enrichment/data.json')));
    return {
        result: extend(defaultEnrichment, r)
    };
};

function filter(all, queryParams, whereClause) {
    var filters = JSON.parse(queryParams).filters;

    if (!filters) {
        return all;
    }

    var wheres = whereClause(filters);

    return all.filter(function(item) {
        return includeItem(item, wheres);
    });
}

function extend(obj1, obj2) {
    for (var prop in obj2) {
        obj1[prop] = obj2[prop];
    }
    return obj1;
}

function sort(data, params) {
    var sortBy = params.sortBy;
    var dir = params.sortDir;

    if (sortBy && _.isObject(data[0][sortBy])) {
        var sortField = sortBy;
        sortBy = function(item) {
            return item[sortField].code;
        };
    }

    data = sortBy ? _.sortBy(data, sortBy) : data;
    if (sortBy && dir && dir === 'desc') {
        data = data.reverse();
    }
    return data;
}

function paginate(data, params) {
    var skip = params.skip;
    var take = params.take;

    if (skip == null || take == null) {
        return data;
    }
    take = skip + take;
    take = take > data.length ? data.length : take;

    return data.slice(skip, take);
}

function getColumnValues(all, column) {
    return _.sortBy(_.unique(all.map(function(item) {
        return item[column];
    }), function(item) {
        return item.code;
    }), function(item) {
        return item.description || null;
    });
}

function getDateFilterFunc(filter) {
    var filterFunc = undefined;
    switch (filter.operator) {
        case 'eq':
            filterFunc = function(item) {
                return moment(item[filter.field]).isSame(filter.value);
            };
            break;
        case 'gte':
            filterFunc = function(item) {
                return moment(item[filter.field]).isAfter(filter.value);
            };
            break;
        case 'lt':
            filterFunc = function(item) {
                return moment(item[filter.field]).isBefore(filter.value);
            };
            break;
    }
    return filterFunc;
}

function getTextFilterFunc(filter) {
    var filterFunc = undefined;
    switch (filter.operator) {
        case 'eq':
            filterFunc = function(item) {
                return item[filter.field] === filter.value;
            };
            break;
        case 'contains':
            filterFunc = function(item) {
                return (item[filter.field] || "").indexOf(filter.value) > -1;
            };
            break;
        case 'startswith':
            filterFunc = function(item) {
                return (item[filter.field] || "").indexOf(filter.value) === 0;
            };
            break;
    }
    return filterFunc;
}

function getWhereClauses(filters) {
    var customFilterFuncMap = {
        'date': getDateFilterFunc,
        'text': getTextFilterFunc
    };

    return filters.map(function(filter) {
        if (filter.type) {
            var filterFunc = customFilterFuncMap[filter.type];
            if (filterFunc) {
                return filterFunc(filter);
            }
        }

        var values = filter.value.split(',');
        var isNullFilter = values.indexOf('null') !== -1;
        if (filter.operator === 'in') {
            return function(item) {
                return item[filter.field] ? values.indexOf(item[filter.field]) !== -1 : isNullFilter;
            };
        }
        if (filter.operator === 'notIn') {
            return function(item) {
                return item[filter.field] ? values.indexOf(item[filter.field]) === -1 : !isNullFilter;
            };
        }
        return undefined;
    });
}

function getWhereClausesForCodeProperty(filters) {
    return filters.map(function(filter) {
        var values = filter.value.split(',');
        var isNullFilter = values.indexOf('null') !== -1;
        if (filter.operator === 'in') {
            return function(item) {
                return item[filter.field].code ? values.indexOf(item[filter.field].code) !== -1 : isNullFilter;
            };
        }
        if (filter.operator === 'notIn') {
            return function(item) {
                return item[filter.field].code ? values.indexOf(item[filter.field].code) === -1 : !isNullFilter;
            };
        }
        return undefined;
    });
}

function includeItem(item, wheres) {
    // apply each where and if any
    return !wheres.some(function(where) {
        if (!where) {
            return false;
        }

        if (!where(item)) {
            return true;
        }
    });
}