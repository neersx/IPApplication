using System.Data.Entity;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names.Payment;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Names
{
    public class NamesModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            ConfigureName(modelBuilder);

            ConfigureClientDetail(modelBuilder);

            ConfigureNameTypeClassification(modelBuilder);

            ConfigureAssociatedName(modelBuilder);

            ConfigureNameAddress(modelBuilder);

            ConfigureNameTelecom(modelBuilder);

            ConfigureNameVariants(modelBuilder);

            ConfigureNameAlias(modelBuilder);

            ConfigureNameRelations(modelBuilder);

            ConfigureState(modelBuilder);

            ConfigureMainContact(modelBuilder);

            ConfigureLocality(modelBuilder);

            ConfigureLocation(modelBuilder);

            ConfigureFilesIn(modelBuilder);

            modelBuilder.Entity<DebtorStatus>();
            modelBuilder.Entity<Titles>();
            modelBuilder.Entity<NameReplaced>();
            modelBuilder.Entity<NameImage>();
            modelBuilder.Entity<NameAddressCpaClient>();
            modelBuilder.Entity<NameText>();
            modelBuilder.Entity<NameLanguage>();
            modelBuilder.Entity<NameAddressSnapshot>();
            modelBuilder.Entity<NameMarginProfile>();
            modelBuilder.Entity<CrRestriction>();
            modelBuilder.Entity<PaymentMethods>();
            modelBuilder.Entity<Reason>();
            modelBuilder.Entity<ExchangeRateSchedule>();
            modelBuilder.Entity<LedgerAccount>();
            modelBuilder.Entity<LeadStatusHistory>();
            modelBuilder.Entity<LeadDetails>();
            modelBuilder.Entity<Correspondence.CorrespondTo>();
        }

        void ConfigureLocation(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<NameLocation>();
        }

        static void ConfigureFilesIn(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<FilesIn>();
        }

        static void ConfigureMainContact(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Name>().HasOptional(n => n.MainContact);
        }

        static void ConfigureNameVariants(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<NameVariant>();
        }

        static void ConfigureNameRelations(DbModelBuilder modelBuilder)
        {
            var nameRelation = modelBuilder.Entity<NameRelation>();

            nameRelation.HasKey(x => x.RelationshipCode);

            modelBuilder.Entity<NameInstruction>().HasKey(n => new { n.Id, n.Sequence });
        }

        static void ConfigureName(DbModelBuilder modelBuilder)
        {
            var name = modelBuilder.Entity<Name>();

            name.HasMany(n => n.NameTypeClassifications)
                .WithRequired()
                .HasForeignKey(n => n.NameId);

            name.HasMany(n => n.NameVariants)
                .WithOptional()
                .HasForeignKey(n => n.NameId);

            name.HasMany(n => n.Addresses)
                .WithRequired()
                .HasForeignKey(n => n.NameId);

            name.HasOptional(n => n.Nationality)
                .WithMany()
                .Map(m => m.MapKey("NATIONALITY"));

            name.HasOptional(n => n.Locality)
                .WithMany()
                .Map(m => m.MapKey("AIRPORTCODE"));

            name.HasOptional(v => v.NameFamily)
                .WithMany()
                .Map(m => m.MapKey("FAMILYNO"));

            modelBuilder.Entity<Individual>();

            var org = modelBuilder.Entity<Organisation>();
            org.HasOptional(o => o.Parent)
               .WithMany()
               .HasForeignKey(o => o.ParentId);

            modelBuilder.Entity<Employee>();
        }

        static void ConfigureNameAddress(DbModelBuilder modelBuilder)
        {
            var nameAddress = modelBuilder.Entity<NameAddress>();
            nameAddress.Map(m => m.ToTable("NAMEADDRESS"));
            nameAddress.HasKey(cd => new { cd.NameId, cd.AddressType, cd.AddressId });

            nameAddress.HasOptional(cd => cd.AddressStatusTableCode)
                       .WithMany()
                       .HasForeignKey(cd => cd.AddressStatus);

            nameAddress.HasRequired(cd => cd.Name)
                       .WithMany()
                       .HasForeignKey(cd => cd.NameId);

            nameAddress.HasRequired(cd => cd.AddressTypeTableCode)
                       .WithMany()
                       .HasForeignKey(cd => cd.AddressType);

            nameAddress.HasRequired(cd => cd.Address)
                       .WithMany()
                       .HasForeignKey(cd => cd.AddressId);
        }

        static void ConfigureNameTelecom(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<NameTelecom>().HasRequired(cd => cd.Telecommunication)
                       .WithMany()
                       .HasForeignKey(cd => cd.TeleCode);

            modelBuilder.Entity<Telecommunication>().HasRequired(tt => tt.TelecomType)
                .WithMany()
                .Map(t => t.MapKey("TELECOMTYPE"));
        }

        static void ConfigureClientDetail(DbModelBuilder modelBuilder)
        {
            var clientDetail = modelBuilder.Entity<ClientDetail>();

            clientDetail.HasOptional(cd => cd.DebtorStatus)
                        .WithMany()
                        .Map(m => m.MapKey("BADDEBTOR"));
        }

        static void ConfigureNameTypeClassification(DbModelBuilder modelBuilder)
        {
            var nameTypeClassification = modelBuilder.Entity<NameTypeClassification>();
            nameTypeClassification.HasRequired(ntc => ntc.NameType)
                                  .WithMany()
                                  .HasForeignKey(ntc => ntc.NameTypeId);
        }

        static void ConfigureAssociatedName(DbModelBuilder modelBuilder)
        {
            var associatedName = modelBuilder.Entity<AssociatedName>();
            associatedName.Map(m => m.ToTable("ASSOCIATEDNAME"));
            associatedName.HasKey(n => new { n.Id, n.RelatedNameId });

            associatedName.HasRequired(oa => oa.RelatedName)
                          .WithMany()
                          .HasForeignKey(oa => oa.RelatedNameId);

            associatedName.HasRequired(oa => oa.Name)
                          .WithMany()
                          .HasForeignKey(oa => oa.Id);

            associatedName.HasOptional(an => an.JobTitle)
                     .WithMany()
                     .Map(m => m.MapKey("JOBROLE"));

            associatedName.HasOptional(an => an.PositionCategory)
                     .WithMany()
                     .Map(m => m.MapKey("POSITIONCATEGORY"));
        }

        static void ConfigureNameAlias(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<NameAliasType>();

            var nameAlias = modelBuilder.Entity<NameAlias>();

            nameAlias.HasRequired(na => na.Name)
                     .WithMany()
                     .HasForeignKey(n => n.NameId);

            nameAlias.HasRequired(na => na.AliasType)
                   .WithMany()
                   .Map(m => m.MapKey("ALIASTYPE"));

            nameAlias.HasOptional(na => na.Country)
                      .WithMany()
                      .Map(m => m.MapKey("COUNTRYCODE"));

            nameAlias.HasOptional(na => na.PropertyType)
                      .WithMany()
                      .Map(m => m.MapKey("PROPERTYTYPE"));
        }

        static void ConfigureState(DbModelBuilder modelBuilder)
        {
            var state = modelBuilder.Entity<State>();

            state.HasKey(cc => new { cc.CountryCode, cc.Code });
        }

        static void ConfigureLocality(DbModelBuilder modelBuilder)
        {
            var locality = modelBuilder.Entity<Locality>();

            locality.HasOptional(l => l.Country)
                        .WithMany()
                        .HasForeignKey(l => l.CountryCode);

            locality.HasOptional(l => l.State)
                        .WithMany()
                        .HasForeignKey(l => new { l.CountryCode, l.StateCode });
        }
    }
}