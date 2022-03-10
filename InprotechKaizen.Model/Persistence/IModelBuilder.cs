using System.Data.Entity;

namespace InprotechKaizen.Model.Persistence
{
    public interface IModelBuilder
    {
        void Build(DbModelBuilder modelBuilder);
    }
}