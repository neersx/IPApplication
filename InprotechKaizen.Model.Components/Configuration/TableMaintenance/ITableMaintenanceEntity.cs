using System;

namespace InprotechKaizen.Model.Components.Configuration.TableMaintenance
{
    public interface ITableMaintenanceEntity<out T> where T : IEquatable<T>
    {
        T Id { get; }
    }
}
