using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.ContactActivities
{
    public class ContactActivitiesModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            ConfigureActivity(modelBuilder);

            ConfigureActivityAttachment(modelBuilder);

            modelBuilder.Entity<DocumentRequest>();
        }

        static void ConfigureActivity(DbModelBuilder modelBuilder)
        {
            var activity = modelBuilder.Entity<Activity>();

            activity.HasMany(a => a.Attachments)
                    .WithOptional()
                    .HasForeignKey(aa => aa.ActivityId);

            activity.HasOptional(a => a.ContactName)
                    .WithMany()
                    .HasForeignKey(a => a.ContactNameId);

            activity.HasOptional(a => a.CallerName)
                    .WithMany()
                    .HasForeignKey(a => a.CallerNameId);

            activity.HasOptional(a => a.RelatedName)
                    .WithMany()
                    .HasForeignKey(a => a.RelatedNameId);

            activity.HasOptional(a => a.ReferredToName)
                    .WithMany()
                    .HasForeignKey(a => a.ReferredToNameId);

            activity.HasOptional(a => a.Case)
                    .WithMany()
                    .HasForeignKey(a => a.CaseId);
        }

        static void ConfigureActivityAttachment(DbModelBuilder modelBuilder)
        {
            var activityAttachment = modelBuilder.Entity<ActivityAttachment>();

            modelBuilder.Entity<AttachmentContent>();

            activityAttachment.HasOptional(aa => aa.AttachmentContent)
                              .WithMany()
                              .Map(m => m.MapKey("ATTACHMENTCONTENTID"));
        }
    }
}