using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Policing
{
    public class PolicingModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            ConfigurePolicing(modelBuilder);
            ConfigurePolicingError(modelBuilder);
            ConfigurePolicingLog(modelBuilder);
            ConfigurePolicingQueueView(modelBuilder);
        }

        static void ConfigurePolicingQueueView(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<PolicingQueueView>();
        }

        static void ConfigurePolicing(DbModelBuilder modelBuilder)
        {
            var policingRequest = modelBuilder.Entity<PolicingRequest>();
            policingRequest.Map(p => p.ToTable("POLICING"));
            
            policingRequest.Property(p => p.DateEntered)
                           .HasColumnType("datetime");

            policingRequest.HasOptional(u => u.User)
                           .WithMany()
                           .HasForeignKey(m => m.IdentityId);

            policingRequest.HasOptional(u => u.NameRecord)
                           .WithMany()
                           .HasForeignKey(m => m.NameNo);

            policingRequest.HasOptional(u => u.NameTypeRecord)
                           .WithMany()
                           .HasForeignKey(m => m.NameType);

            policingRequest.HasOptional(u => u.Event)
                           .WithMany()
                           .HasForeignKey(m => m.EventNo);

            policingRequest.HasOptional(u => u.Case)
                           .WithMany()
                           .HasForeignKey(m => m.CaseId);

            policingRequest.HasOptional(u => u.CaseTypeRecord)
                           .WithMany()
                           .HasForeignKey(m => m.CaseType);

            policingRequest.HasOptional(u => u.PropertyTypeRecord)
                           .WithMany()
                           .HasForeignKey(m => m.PropertyType);

            policingRequest.HasOptional(u => u.JurisdictionRecord)
                           .WithMany()
                           .HasForeignKey(m => m.Jurisdiction);

            policingRequest.HasOptional(u => u.SubTypeRecord)
                           .WithMany()
                           .HasForeignKey(m => m.SubType);

            policingRequest.HasOptional(u => u.ActionRecord)
                           .WithMany()
                           .HasForeignKey(m => m.Action);
        }

        static void ConfigurePolicingError(DbModelBuilder modelBuilder)
        {
            var policingError = modelBuilder.Entity<PolicingError>();
            policingError.Map(p => p.ToTable("POLICINGERRORS"));
            policingError.HasKey(p => new {p.StartDateTime, p.ErrorSeqNo});

            policingError.Property(p => p.StartDateTime)
                         .HasColumnType("datetime");

            policingError.HasOptional(u => u.Case)
                         .WithMany()
                         .HasForeignKey(m => m.CaseId);

            policingError.HasRequired(u => u.PolicingLog)
                         .WithMany()
                         .HasForeignKey(m => m.StartDateTime);
        }

        static void ConfigurePolicingLog(DbModelBuilder modelBuilder)
        {
            var policingLog = modelBuilder.Entity<PolicingLog>();
            policingLog.Map(p => p.ToTable("POLICINGLOG"));
            policingLog.HasKey(p => p.StartDateTime);
        }
    }
}