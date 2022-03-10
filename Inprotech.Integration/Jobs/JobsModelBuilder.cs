using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Jobs
{
    public class JobsModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Job>();

            modelBuilder.Entity<JobExecution>();
        }
    }
}
