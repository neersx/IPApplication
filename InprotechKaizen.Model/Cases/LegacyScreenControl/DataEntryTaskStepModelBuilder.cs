using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Cases.LegacyScreenControl
{
    public class DataEntryTaskStepModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            var dataEntryTaskStep = modelBuilder.Entity<DataEntryTaskStep>();
            dataEntryTaskStep.Map(m => m.ToTable("SCREENCONTROL"));
            dataEntryTaskStep.HasKey(sc => new {sc.CriteriaId, sc.ScreenId, sc.ScreenName});

            dataEntryTaskStep.HasRequired(dets => dets.Screen).WithMany().HasForeignKey(dets => dets.ScreenName);

            dataEntryTaskStep.HasOptional(dets => dets.NameType)
                             .WithMany()
                             .HasForeignKey(dets => dets.NameTypeCode);

            dataEntryTaskStep.HasOptional(dets => dets.CreateAction).WithMany().HasForeignKey(dets => dets.CreateActionId);
            dataEntryTaskStep.HasOptional(dets => dets.Checklist).WithMany().HasForeignKey(dets => dets.ChecklistType);
            dataEntryTaskStep.HasOptional(dets => dets.Relationship).WithMany().HasForeignKey(dets => dets.RelationshipId);
            dataEntryTaskStep.HasOptional(dets => dets.TextType).WithMany().HasForeignKey(dets => dets.TextTypeId);
        }
    }
}