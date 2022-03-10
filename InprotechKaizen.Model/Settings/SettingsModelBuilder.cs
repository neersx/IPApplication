using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Settings
{
    public class SettingsModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ConfigSetting>();
        }
    }
}