using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.AuditTrail
{
    public class AuditTrailModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            ConfigureAuditLogTables(modelBuilder);
            ConfigureSession(modelBuilder);
            ConfigureTransaction(modelBuilder);
        }

        static void ConfigureAuditLogTables(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<AuditLogTable>();
        }

        static void ConfigureSession(DbModelBuilder modelBuilder)
        {
            var operatorSession = modelBuilder.Entity<OperatorSession>();
            operatorSession.Map(m => m.ToTable("SESSION"));

            operatorSession.HasRequired(o => o.User)
                           .WithMany()
                           .Map(m => m.MapKey("IDENTITYID"));
        }

        static void ConfigureTransaction(DbModelBuilder modelBuilder)
        {
            var transaction = modelBuilder.Entity<TransactionInfo>();
            
            transaction.HasOptional(t => t.Session)
                       .WithMany()
                       .Map(m => m.MapKey("SESSIONNO"));
        }
    }
}