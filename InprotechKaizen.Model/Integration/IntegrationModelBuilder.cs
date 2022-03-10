using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Integration
{
    public class IntegrationModelBuilder : IModelBuilder
    {
        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<CpaGlobalIdentifier>();
            modelBuilder.Entity<FileCase>();
        }
    }
}