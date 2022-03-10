
Array.prototype.max = function() {
    return Math.max.apply(null, this);
};

Array.prototype.min = function() {
    return Math.min.apply(null, this);
};

Array.prototype.firstOrDefault = function (predicate) {
    if (!predicate) {
        if (this.length > 0)
            return this[0];
        else 
            return null;        
    }
        
    for (var i = 0; i < this.length; i++) {        
        if (predicate(this[i])) return this[i];
    }

    return null;
};

Array.prototype.first = function(predicate) {
    var f = this.firstOrDefault(predicate);
    if (f == null)
        throw "Collection is empty.";
    return f;
};

Array.prototype.single = function(predicate) {
    if (!predicate) {
        if (this.length == 1)
            return this[0];
        throw "Collection contains more than one element";
    }

    var item = null;
    for (var i = 0; i < this.length; i++) {
        if (predicate(this[i]) === false)
            continue;

        if (item != null)
            throw "Collection contains more than one matches";

        item = this[i];
    }

    if (item == null)
        throw "Collection contains no matching item";

    return item;
};

Array.prototype.any = function (predicate) {
    return this.firstOrDefault(predicate) !== null;
};

Array.prototype.where = function (predicate) {
    var results = [];
    for (var i = 0; i < this.length; i++) {
        if (predicate(this[i])) results.push(this[i]);
    }

    return results;
};

Array.prototype.all = function (predicate) {
    for (var i = 0; i < this.length; i++) {
        if (predicate(this[i]) === false)
            return false;
    }
    return true;
};

Array.prototype.select = function(selector) {
    var selection = [];
    for (var i = 0; i < this.length; i++) {        
            selection.push(selector(this[i]));
    }
    return selection;
};

Array.prototype.selectMany = function(selector) {
    var selection = [];

    for (var i = 0; i < this.length; i++) {
        var that = selector(this[i]);

        if ((that instanceof  Array) === false)
            throw { message: "An array selection is required." };
        
        for(var j = 0; j < that.length; j++) {
            selection.push(that[j]);
        }
    }
    
    return selection;
};

Array.prototype.clear = function() {
    while (this.length > 0)
        this.pop();
};

Array.prototype.sum = function() {
    for (var i = 0, sum = 0; i < this.length; sum += this[i++]) ;
    return sum;
};

if (!Array.prototype.forEach) {
    Array.prototype.forEach = function (fn, scope) {
        for (var i = 0, len = this.length; i < len; ++i) {
            fn.call(scope, this[i], i, this);
        }
    };
}