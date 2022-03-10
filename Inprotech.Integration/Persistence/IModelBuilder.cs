using System.Data.Entity;

namespace Inprotech.Integration.Persistence
{
    public interface IModelBuilder
    {
        void Build(DbModelBuilder modelBuilder);
    }
}