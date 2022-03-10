using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Ede
{
    public class EdeModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            ConfigureTransactionHeader(modelBuilder);

            ConfigureTransactionBody(modelBuilder);

            ConfigureSenderDetails(modelBuilder);

            ConfigureProcessRequest(modelBuilder);

            ConfigureImportBatch(modelBuilder);

            ConfigureIssues(modelBuilder);

            ConfigureIdentifierNumberDetails(modelBuilder);

            ConfigureName(modelBuilder);

            ConfigureUnresolvedNames(modelBuilder);

            ConfigureExternalSystem(modelBuilder);

            ConfigureRequestType(modelBuilder);

            ConfigureFormattedAttentionOfName(modelBuilder);

            ConfigureTransactionContentDetails(modelBuilder);
        }

        static void ConfigureRequestType(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<EdeRequestType>();
        }

        static void ConfigureExternalSystem(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ExternalSystem>();
        }

        static void ConfigureName(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<EdeName>();
        }

        static void ConfigureUnresolvedNames(DbModelBuilder modelBuilder)
        {
            var en = modelBuilder.Entity<ExternalName>();
            en.HasOptional(e => e.ExternalNameAddress)
                .WithRequired()
                .Map(e => e.MapKey("EXTERNALNAMEID"));

            modelBuilder.Entity<ExternalNameMapping>().ToTable("EXTERNALNAMEMAPPING");
            modelBuilder.Entity<EdeAddressBook>().ToTable("EDEADDRESSBOOK");
        }

        static void ConfigureProcessRequest(DbModelBuilder modelBuilder)
        {
            var pr = modelBuilder.Entity<ProcessRequest>();
            pr.HasOptional(p => p.Status)
              .WithMany()
              .Map(c => c.MapKey("STATUSCODE"));
        }

        static void ConfigureImportBatch(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ImportBatch>();
        }

        static void ConfigureTransactionHeader(DbModelBuilder modelBuilder)
        {
            var th = modelBuilder.Entity<EdeTransactionHeader>();

            th.HasOptional(t => t.BatchStatus)
              .WithMany()
              .Map(t => t.MapKey("BATCHSTATUS"));

            th.HasMany(t => t.TransactionBodies)
              .WithOptional()
              .HasForeignKey(tb => tb.BatchId);

            th.HasMany(n => n.UnresolvedNames)
              .WithOptional()
              .HasForeignKey(n => n.BatchId);
        }

        static void ConfigureTransactionBody(DbModelBuilder modelBuilder)
        {
            var tb = modelBuilder.Entity<EdeTransactionBody>();

            tb.HasKey(t => new { t.BatchId, t.TransactionIdentifier });

            tb.HasMany(t => t.OutstandingIssues)
              .WithOptional()
              .HasForeignKey(t => new { t.BatchId, t.TransactionIdentifier });

            tb.HasKey(t => new { t.BatchId, t.TransactionIdentifier })
              .HasMany(t => t.DescriptionDetails)
              .WithOptional()
              .HasForeignKey(t => new { t.BatchId, t.TransactionIdentifier });

            tb.HasKey(t => new { t.BatchId, t.TransactionIdentifier })
              .HasMany(t => t.IdentifierNumberDetails)
              .WithOptional()
              .HasForeignKey(t => new { t.BatchId, t.TransactionIdentifier });

            tb.HasOptional(t => t.TransactionStatus)
              .WithMany()
              .Map(t => t.MapKey("TRANSSTATUSCODE"));

            tb.HasOptional(t => t.CaseDetails)
                .WithOptionalPrincipal()
                .Map(c => c.MapKey(new[] { "BATCHNO", "TRANSACTIONIDENTIFIER" }));
             
            tb.HasOptional(t => t.CaseMatch)
                .WithOptionalPrincipal()
                .Map(c => c.MapKey(new[] { "BATCHNO", "TRANSACTIONIDENTIFIER" }));
        }

        static void ConfigureIssues(DbModelBuilder modelBuilder)
        {
            var oi = modelBuilder.Entity<EdeOutstandingIssues>();
            
            modelBuilder.Entity<EdeStandardIssues>();

            oi.HasRequired(o => o.StandardIssue)
              .WithMany()
              .Map(o => o.MapKey("ISSUEID"));
        }

        static void ConfigureSenderDetails(DbModelBuilder modelBuilder)
        {
            var sd = modelBuilder.Entity<EdeSenderDetails>();

            sd.HasOptional(s => s.TransactionHeader)
              .WithMany()
              .Map(s => s.MapKey("BATCHNO"));
        }

        static void ConfigureIdentifierNumberDetails(DbModelBuilder modelBuilder)
        {
            var ind = modelBuilder.Entity<EdeIdentifierNumberDetails>();

            ind.HasOptional(n => n.NumberType)
                .WithMany()
                .Map(n => n.MapKey("IDENTIFIERNUMBERCODE_T"));
        }

        static void ConfigureFormattedAttentionOfName(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<EdeFormattedAttnOf>();
        }

        static void ConfigureTransactionContentDetails(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<EdeTransactionContentDetails>();
        }
    }
}
