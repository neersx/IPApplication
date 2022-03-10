using InprotechKaizen.Model.Persistence;
using System.Data.Entity;

namespace InprotechKaizen.Model.TaskPlanner
{
   public class TaskPlannerTabModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<TaskPlannerTab>().Map(m => m.ToTable("TASKPLANNERTAB"));
            modelBuilder.Entity<TaskPlannerTabsByProfile>().Map(m => m.ToTable("TASKPLANNERTABSBYPROFILE"));
        }
    }
}
