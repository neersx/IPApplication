using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.ExternalApplications
{
    public class ExternalApplicationsModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ExternalApplication>();
            modelBuilder.Entity<ExternalApplicationToken>();
            modelBuilder.Entity<OneTimeToken>();
        }
    }
}