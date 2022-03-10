using System;
using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Cases.Events
{
    public class EventsModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if(modelBuilder == null) throw new ArgumentNullException("modelBuilder");

            var detailDate = modelBuilder.Entity<AvailableEvent>();

            detailDate.HasRequired(dd => dd.Event)
                      .WithMany()
                      .HasForeignKey(dd => dd.EventId);

            detailDate.HasKey(dd => new {dd.CriteriaId, dd.DataEntryTaskId, dd.EventId});

            modelBuilder.Entity<EventNoteType>();
            modelBuilder.Entity<EventText>().HasOptional(e => e.EventNoteType).WithMany().HasForeignKey(c =>c.EventNoteTypeId);
        }
    }
}