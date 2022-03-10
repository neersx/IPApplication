using System.Data.Entity;
using InprotechKaizen.Model.Configuration.Items;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Search.Export;

namespace InprotechKaizen.Model.Configuration
{
    public class CommonModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            var siteControl = modelBuilder.Entity<SiteControl.SiteControl>();
            siteControl.Map(m => m.ToTable("SITECONTROL")).HasKey(s => s.Id);

            siteControl.HasMany(_ => _.Components)
                       .WithMany()
                       .Map(_ => _.ToTable("SITECONTROLCOMPONENTS").MapLeftKey("SITECONTROLID").MapRightKey("COMPONENTID"));

            siteControl.HasMany(_ => _.Tags)
                       .WithMany()
                       .Map(_ => _.ToTable("SITECONTROLTAGS").MapLeftKey("SITECONTROLID").MapRightKey("TAGID"));

            var configurationItem = modelBuilder.Entity<ConfigurationItem>();
            modelBuilder.Entity<ConfigurationItemGroup>();

            configurationItem.HasMany(_ => _.Components)
                             .WithMany()
                             .Map(_ => _.ToTable("CONFIGURATIONITEMCOMPONENTS").MapLeftKey("CONFIGITEMID").MapRightKey("COMPONENTID"));

            configurationItem.HasMany(_ => _.Tags)
                             .WithMany()
                             .Map(_ => _.ToTable("CONFIGURATIONITEMTAGS").MapLeftKey("CONFIGITEMID").MapRightKey("TAGID"));

            var tableType = modelBuilder.Entity<TableType>();
            tableType.Map(m => m.ToTable("TABLETYPE"));
            tableType.HasKey(tt => tt.Id);

            var selectionTypes = modelBuilder.Entity<SelectionTypes>();
            selectionTypes.Map(m => m.ToTable("SELECTIONTYPES"));
            selectionTypes.HasKey(st => new {st.ParentTable, st.TableTypeId});

            var links = modelBuilder.Entity<Link>();
            links.HasKey(l => l.CategoryId);

            var appsData = modelBuilder.Entity<TempStorage.TempStorage>();
            appsData.Map(m => m.ToTable("TEMPSTORAGE"));

            modelBuilder.Entity<TmClass>();
            modelBuilder.Entity<TableAttributes>();
            modelBuilder.Entity<ReleaseVersion>();
            modelBuilder.Entity<Component>();
            modelBuilder.Entity<Tag>();
            modelBuilder.Entity<ProtectCodes>();
            modelBuilder.Entity<LastInternalCode>();
            modelBuilder.Entity<ClassItem>();
            modelBuilder.Entity<CaseClassItem>();
            modelBuilder.Entity<Frequency>();
            modelBuilder.Entity<ReportContentResult>();
            modelBuilder.Entity<ReportToolExportFormat>();

            var device = modelBuilder.Entity<Device>();
            device.Map(m => m.ToTable("RESOURCE"));
            device.HasKey(tc => tc.Id);
        }
    }
}