using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.DataValidation
{
    public class DataValidationModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DataValidation>().HasKey(d => new { d.Id });
        }
    }
}
