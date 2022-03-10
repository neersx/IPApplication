using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Profiles
{
    public class ProfilesModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<SettingValues>().HasOptional(s => s.User).WithMany().Map(c => c.MapKey("IDENTITYID"));
            modelBuilder.Entity<ExternalSettings>();
        }
    }
}