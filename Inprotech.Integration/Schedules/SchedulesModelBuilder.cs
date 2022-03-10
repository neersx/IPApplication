using System;
using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Schedules
{
    public class SchedulesModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if(modelBuilder == null) throw new ArgumentNullException("modelBuilder");
            modelBuilder.Entity<Schedule>();

            modelBuilder.Entity<ScheduleFailure>();

            modelBuilder.Entity<ScheduleExecution>();

            modelBuilder.Entity<ScheduleRecoverable>();

            modelBuilder.Entity<UnrecoverableArtefact>();

            modelBuilder.Entity<ScheduleExecutionArtifact>();

            modelBuilder.Entity<ProcessIdsToCleanup>();
        }
    }
}