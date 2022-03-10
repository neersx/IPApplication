using InprotechKaizen.Model.Persistence;
using System.Data.Entity;

namespace InprotechKaizen.Model.GlobalCaseChange
{
    public class GlobalCaseChangesModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            var gcCasesResults = modelBuilder.Entity<GlobalCaseChangeResults>();
            gcCasesResults.HasRequired(_ => _.BackgroundProcess).WithMany()
                          .HasForeignKey(_ => _.Id);

            gcCasesResults.HasRequired(_ => _.Case).WithMany()
                          .HasForeignKey(_ => _.CaseId);
        }
    }
}
