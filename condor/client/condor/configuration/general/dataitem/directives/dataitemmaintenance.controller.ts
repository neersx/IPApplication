interface IDataItemMaintenanceScope extends ng.IScope {
    model;
    maintenance;
    errors;
    saveCall: boolean;
}

class DataItemMaintenanceController {
    static $inject = ['$scope', 'states', 'dataItemService', 'notificationService'];

    constructor(private $scope: IDataItemMaintenanceScope, private states, private dataItemService, private notificationService) { }

    removeError = (fieldId) => {
        this.$scope.errors = _.without(this.$scope.errors, _.findWhere(this.$scope.errors, {
            field: fieldId
        }));
    }

    getError = (field) => {
        return _.find(this.$scope.errors, function (error: any) {
            return error.field === field;
        });
    }

    resetSqlError = () => {
        let error;
        if (this.$scope.model.isSqlStatement) {
            error = this.getError('statement');
            if (error !== null) {
                this.removeError('statement');
            }
        } else {
            error = this.getError('procedurename');
            if (error !== null) {
                this.removeError('procedurename');
            }
        }
    }

    resetSql = () => {
        if (this.$scope.model.state === this.states.adding) {
            this.$scope.model.sql = null;
        }
        this.resetSqlError();
    }

    afterValidate = (response: any) => {
        if (response.data == null) {
            this.notificationService.success('dataItem.maintenance.testedsuccess');
        }
        // tslint:disable-next-line:one-line
        else {
            this.$scope.errors = response.data.errors;
            this.notificationService.alert({
                title: 'field.errors.invalidsql',
                message: this.getError(this.$scope.errors[0].field).message,
                errors: _.where(this.$scope.errors, {
                    field: null
                })
            });
        }
    }

    validateSql = () => {
        this.$scope.errors = null;
        this.$scope.saveCall = false;
        this.dataItemService.validate(this.$scope.model)
            .then(this.afterValidate.bind(this));
    }

    shouldDisable = () => {
        return (this.$scope.model && this.$scope.model.isSqlStatement && (!this.$scope.model.sql || (this.$scope.model.sql && (this.$scope.model.sql.sqlStatement === '' || this.$scope.model.sql.sqlStatement === undefined)))) ||
            (this.$scope.model && !this.$scope.model.isSqlStatement && (!this.$scope.model.sql || (this.$scope.model.sql && (this.$scope.model.sql.storedProcedure === '' || this.$scope.model.sql.storedProcedure === undefined)))) ||
            (this.$scope.model && this.$scope.model.isSqlStatement && this.$scope.maintenance && this.$scope.maintenance.statement && this.$scope.maintenance.statement.$error.ipRequired) ||
            (this.$scope.model && !this.$scope.model.isSqlStatement && this.$scope.maintenance && this.$scope.maintenance.procedurename && this.$scope.maintenance.procedurename.$error.ipRequired);
    }
}


angular.module('inprotech.configuration.general.dataitem')
    .controller('ipDataItemMaintenanceController', DataItemMaintenanceController);