using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Reminders
{
    public class RemindersModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<StaffReminder>();
            modelBuilder.Entity<AlertRule>();
            modelBuilder.Entity<AlertTemplate>();
        }
    }
}
