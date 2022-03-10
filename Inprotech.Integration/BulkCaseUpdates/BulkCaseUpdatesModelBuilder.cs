using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public class BulkCaseUpdatesModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<BulkCaseUpdatesSchedule>();
        }
    }
}
