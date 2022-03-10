using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.DataSources
{
    public class DataSourcesModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DataSourceAvailability>();
        }
    }
}
