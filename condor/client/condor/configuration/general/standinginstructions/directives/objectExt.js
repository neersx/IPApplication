angular.module('inprotech.configuration.general.standinginstructions').factory('ObjectExt', function() {
    'use strict';

    function ObjectExt(object) {
        this.obj = object;
        this.status = 'none';
        this.isDeleted = false;
        this.newlyAdded = false;
        this.isSaved = false;
        this.serverErrorMsg = '';
    }

    ObjectExt.prototype = {
        getErrorText: function(error) {
            var self = this;

            if (self.serverError) {
                return self.serverErrorMsg;
            }

            if (!error || _.isEmpty(error)) {
                return '';
            }
            if (error.required) {
                return 'field.errors.required';
            }

            if (error.maxlength) {
                return 'field.errors.maxlength';
            }

            if (error.isUnique) {
                return 'field.errors.notunique';
            }
        },

        getObj: function() {
            var self = this;
            return _.clone(self.obj);
        },

        changeStatus: function(isReverted) {
            var self = this;
            if (!isReverted) {
                self.isSaved = false;
            }
            self.serverError = false;
            if (self.status !== 'added') {
                self.status = isReverted ? 'none' : 'updated';
            }
        },

        delete: function() {
            var self = this;
            self.serverError = false;
            self.isDeleted = !self.isDeleted;
        },

        setNew: function() {
            var self = this;
            self.status = 'added';
            self.newlyAdded = true;

            return this;
        },

        resetNewlyAdded: function() {
            var self = this;
            if (self.newlyAdded) {
                self.newlyAdded = false;
            }
        },

        setError: function(errorStr) {
            var self = this;
            self.serverError = true;
            self.serverErrorMsg = errorStr;
        }
    };

    return ObjectExt;
});
