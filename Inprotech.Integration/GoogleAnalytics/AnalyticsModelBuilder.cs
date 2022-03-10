using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.GoogleAnalytics
{
    public class AnalyticsModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ServerAnalyticsData>();

            modelBuilder.Entity<ServerTransactionalDataSink>();
        }
    }
}