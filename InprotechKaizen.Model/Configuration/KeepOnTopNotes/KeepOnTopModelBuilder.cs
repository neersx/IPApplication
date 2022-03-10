using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Configuration.KeepOnTopNotes
{
    public class KeepOnTopModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<KeepOnTopTextType>();
            var kotCaseType = modelBuilder.Entity<KeepOnTopCaseType>().HasKey(ct => new { ct.KotTextTypeId, ct.CaseTypeId });
            kotCaseType.HasRequired(ct => ct.KotTextType)
                       .WithMany(c => c.KotCaseTypes)
                       .HasForeignKey(ct => ct.KotTextTypeId);

            var kotNameType = modelBuilder.Entity<KeepOnTopNameType>().HasKey(ct => new { ct.KotTextTypeId, ct.NameTypeId });
            kotNameType.HasRequired(ct => ct.KotTextType)
                       .WithMany(c => c.KotNameTypes)
                       .HasForeignKey(ct => ct.KotTextTypeId);

            var kotRole = modelBuilder.Entity<KeepOnTopRole>().HasKey(ct => new { ct.KotTextTypeId, ct.RoleId });
            kotRole.HasRequired(ct => ct.KotTextType)
                       .WithMany(c => c.KotRoles)
                       .HasForeignKey(ct => ct.KotTextTypeId);
        }
    }
}
