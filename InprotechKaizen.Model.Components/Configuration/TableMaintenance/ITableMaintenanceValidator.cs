using System;

namespace InprotechKaizen.Model.Components.Configuration.TableMaintenance
{
    public interface ITableMaintenanceValidator<in T> where T : IEquatable<T>
    {
        TableMaintenanceValidationResult ValidateOnDelete(T id);

        TableMaintenanceValidationResult ValidateOnPost(object entity);

        TableMaintenanceValidationResult ValidateOnPut(object entity, object modifiedEntity);
    }
}