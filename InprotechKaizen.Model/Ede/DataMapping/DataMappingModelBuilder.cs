using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    public class DataMappingModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DataSource>();

            modelBuilder.Entity<EncodedValue>();

            modelBuilder.Entity<EncodingScheme>();

            modelBuilder.Entity<EncodingStructure>();

            modelBuilder.Entity<Mapping>();

            modelBuilder.Entity<MapScenario>();

            modelBuilder.Entity<MapStructure>();

            modelBuilder.Entity<DataMap>();
            modelBuilder.Entity<DataWizard>();

        }
    }
}
