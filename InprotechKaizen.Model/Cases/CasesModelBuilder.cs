using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Cases
{
    [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
    public class CasesModelBuilder : IModelBuilder
    {
        [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
        public void Build(DbModelBuilder modelBuilder)
        {
            ConfigureCase(modelBuilder);
            ConfigureCaseFilePart(modelBuilder);

            ConfigureValidAction(modelBuilder);

            ConfigureOpenAction(modelBuilder);

            ConfigureProperty(modelBuilder);

            ConfigureLocation(modelBuilder);

            ConfigureGlobalNameChange(modelBuilder);

            ConfigureCaseName(modelBuilder);

            ConfigureAddress(modelBuilder);

            ConfigureActivityRequest(modelBuilder);

            ConfigureCaseActivityHistory(modelBuilder);

            ConfigureNameGroups(modelBuilder);

            ConfigureCaseText(modelBuilder);

            ConfigureRelatedCase(modelBuilder);

            ConfigureNameType(modelBuilder);

            ConfigureCaseInstructions(modelBuilder);

            ConfigureCaseReferenceAllocations(modelBuilder);

            ConfigureSanityCheckResults(modelBuilder);
            ConfigureExchangeRateVariations(modelBuilder);

            ConfigureExchangeRateVariations(modelBuilder);

            modelBuilder.Entity<Action>();

            modelBuilder.Entity<CheckList>();
            modelBuilder.Entity<CaseChecklist>();
            modelBuilder.Entity<ExchangeRateHistory>();

            var importanceLevel = modelBuilder.Entity<Importance>();
            importanceLevel.Map(m => m.ToTable("IMPORTANCE"));

            var cpaSentBatchNo = modelBuilder.Entity<CpaSend>();
            cpaSentBatchNo.Map(m => m.ToTable("CPASEND"));

            var cpaEventRenewalDate = modelBuilder.Entity<CpaEvent>();
            cpaEventRenewalDate.Map(m => m.ToTable("CPAEVENT"));

            var cpaPortfolioDate = modelBuilder.Entity<CpaPortfolio>();
            cpaPortfolioDate.Map(m => m.ToTable("CPAPORTFOLIO"));

            var officialNumber = modelBuilder.Entity<OfficialNumber>();
            officialNumber.Map(m => m.ToTable("OFFICIALNUMBERS"));

            modelBuilder.Entity<PropertyType>();

            modelBuilder.Entity<Country>().HasMany(c => c.States)
                        .WithRequired(c => c.Country)
                        .HasForeignKey(c => c.CountryCode);

            var countryGroup = modelBuilder.Entity<CountryGroup>();
            countryGroup.Map(m => m.ToTable("COUNTRYGROUP"));
            countryGroup.HasKey(cg => new { cg.Id, cg.MemberCountry });

            var countryText = modelBuilder.Entity<CountryText>();
            countryText.Map(m => m.ToTable("COUNTRYTEXT"));

            modelBuilder.Entity<CountryFlag>();

            modelBuilder.Entity<CopyProfile>();

            var countryHoliday = modelBuilder.Entity<CountryHoliday>();
            countryHoliday.Map(m => m.ToTable("HOLIDAYS"));

            var countryValidNumber = modelBuilder.Entity<CountryValidNumber>();
            countryValidNumber.Map(m => m.ToTable("VALIDATENUMBERS"));
            countryValidNumber.HasRequired(co => co.Property).WithMany().HasForeignKey(co => co.PropertyId);
            countryValidNumber.HasRequired(co => co.NumberType).WithMany().HasForeignKey(co => co.NumberTypeId);
            countryValidNumber.HasOptional(co => co.CaseType).WithMany().HasForeignKey(co => co.CaseTypeId);
            countryValidNumber.HasOptional(co => co.SubType).WithMany().HasForeignKey(co => co.SubTypeId);

            countryValidNumber.HasOptional(co => co.CaseCategory).WithMany().HasForeignKey(co => new { co.CaseTypeId, co.CaseCategoryId });

            countryValidNumber.HasOptional(co => co.ValidProperty)
                              .WithMany()
                              .HasForeignKey(co => new { co.CountryId, co.PropertyId });
            countryValidNumber.HasOptional(co => co.ValidSubType)
                              .WithMany()
                              .HasForeignKey(co => new { co.CountryId, co.PropertyId, co.CaseTypeId, co.CaseCategoryId, co.SubTypeId });
            countryValidNumber.HasOptional(co => co.ValidCaseCategory)
                              .WithMany()
                              .HasForeignKey(co => new { co.CountryId, co.PropertyId, co.CaseTypeId, co.CaseCategoryId });

            modelBuilder.Entity<CaseType>().HasOptional(ct => ct.TextType).WithMany().HasForeignKey(ct => ct.KotTextType);

            var caseStatus = modelBuilder.Entity<Status>();
            caseStatus.Map(m => m.ToTable("STATUS"));
            caseStatus.HasKey(cs => cs.Id);

            modelBuilder.Entity<CaseCategory>();

            var profitCentre = modelBuilder.Entity<ProfitCentre>();
            profitCentre.Map(m => m.ToTable("PROFITCENTRE"));
            profitCentre.HasKey(pc => pc.Id);
            profitCentre.HasOptional(nt => nt.EntityName)
                        .WithMany()
                        .HasForeignKey(nt => nt.EntityId);

            modelBuilder.Entity<SubType>();

            var family = modelBuilder.Entity<Family>();
            family.Map(m => m.ToTable("CASEFAMILY"));
            family.HasKey(f => f.Id);

            var familySearchResult = modelBuilder.Entity<FamilySearchResult>();
            familySearchResult.Map(m => m.ToTable("FAMILYSEARCHRESULT"));
            familySearchResult.HasKey(f => f.Id);

            var nameSearchResult = modelBuilder.Entity<NameSearchResult>();
            nameSearchResult.Map(m => m.ToTable("NAMESEARCHRESULT"));
            nameSearchResult.HasKey(f => f.Id);

            var caseEventILogs = modelBuilder.Entity<CaseEventILog>();
            caseEventILogs.Map(m => m.ToTable("CASEEVENT_iLog"))
                     .HasKey(ce => new { ce.CaseId, ce.EventNo, ce.Cycle });

            var caseEvent = modelBuilder.Entity<CaseEvent>();
            caseEvent.Map(m => m.ToTable("CASEEVENT"))
                     .HasKey(ce => new { ce.CaseId, ce.EventNo, ce.Cycle });

            caseEvent.HasRequired(_ => _.Event)
                     .WithMany()
                     .HasForeignKey(_ => _.EventNo);

            modelBuilder.Entity<CaseEventText>();

            modelBuilder.Entity<Office>();

            var tableCodes = modelBuilder.Entity<TableCode>();
            tableCodes.Map(m => m.ToTable("TABLECODES"));
            tableCodes.HasKey(tc => tc.Id);

            var tableAttributes = modelBuilder.Entity<TableAttributes>();
            tableAttributes.HasRequired(x => x.TableCode)
                           .WithMany()
                           .HasForeignKey(x => x.TableCodeId);

            var caseName = modelBuilder.Entity<CaseName>();
            caseName.Map(m => m.ToTable("CASENAME"))
                    .HasKey(cn => new { cn.CaseId, cn.NameTypeId, cn.NameId, cn.Sequence });

            var caseImage = modelBuilder.Entity<CaseImage>();
            caseImage.Map(m => m.ToTable("CASEIMAGE"))
                     .HasKey(ci => new { ci.CaseId, ci.ImageId });

            var images = modelBuilder.Entity<Image>();
            images.Map(m => m.ToTable("IMAGE"))
                  .HasKey(i => i.Id);

            var imageDetail = modelBuilder.Entity<ImageDetail>();
            imageDetail.Map(m => m.ToTable("IMAGEDETAIL"))
                       .HasKey(i => i.ImageId);

            var caseAccessAccount = modelBuilder.Entity<CaseAccess>();
            caseAccessAccount.Map(m => m.ToTable("ACCOUNTCASECONTACT"))
                             .HasKey(ca => new { ca.AccountId, ca.AccountCaseId });

            modelBuilder.Entity<CaseIndexes>();

            modelBuilder.Entity<CaseList>();

            modelBuilder.Entity<CaseListSearchResult>();

            modelBuilder.Entity<DesignElement>();

            modelBuilder.Entity<CaseNameRequest>();
            modelBuilder.Entity<CaseProfitCentre>();
            modelBuilder.Entity<CpaUpdate>();

            modelBuilder.Entity<Reciprocity>();
            modelBuilder.Entity<CaseStandingInstructionsNamesView>();
        }

        void ConfigureCaseReferenceAllocations(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<CaseReferenceAllocation>();
        }

        static void ConfigureNameType(DbModelBuilder modelBuilder)
        {
            var nameType = modelBuilder.Entity<NameType>();

            nameType.HasOptional(nt => nt.PathNameRelation)
                    .WithMany()
                    .HasForeignKey(nt => nt.PathRelationship);

            nameType.HasOptional(nt => nt.ChangeEvent)
                    .WithMany()
                    .HasForeignKey(nt => nt.ChangeEventNo);

            nameType.HasOptional(nt => nt.DefaultName)
                    .WithMany()
                    .HasForeignKey(nt => nt.DefaultNameId);
            nameType.HasOptional(nt => nt.TextType)
                    .WithMany()
                    .HasForeignKey(nt => nt.KotTextType);
        }

        static void ConfigureNameGroups(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<NameGroup>();

            var nameGroupMember = modelBuilder.Entity<NameGroupMember>();
            nameGroupMember.HasRequired(cd => cd.NameType)
                           .WithMany()
                           .HasForeignKey(cd => cd.NameTypeCode);
        }

        static void ConfigureCaseText(DbModelBuilder modelBuilder)
        {
            var caseText = modelBuilder.Entity<CaseText>();
            modelBuilder.Entity<ClassFirstUse>();

            caseText.HasRequired(ct => ct.TextType)
                    .WithMany()
                    .HasForeignKey(ct => ct.Type);

            caseText.HasOptional(ct => ct.LanguageValue)
                    .WithMany()
                    .HasForeignKey(ct => ct.Language);
        }

        static void ConfigureRelatedCase(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<RelatedCase>();
            modelBuilder.Entity<CaseRelation>();
        }

        static void ConfigureCaseInstructions(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<CaseInstruction>().HasKey(c => new { c.Id, c.InstructionType });
            modelBuilder.Entity<InstructionDefinition>();
            modelBuilder.Entity<InstructionResponse>();
        }

        static void ConfigureValidAction(DbModelBuilder modelBuilder)
        {
            var validAction = modelBuilder.Entity<ValidAction>();
            validAction.Map(va => va.ToTable("VALIDACTION"));
            validAction.HasKey(va => new { va.CountryId, va.PropertyTypeId, va.CaseTypeId, va.ActionId });

            validAction.HasRequired(va => va.Action)
                       .WithMany()
                       .HasForeignKey(va => va.ActionId);

            validAction.HasRequired(va => va.PropertyType)
                       .WithMany()
                       .HasForeignKey(va => va.PropertyTypeId);

            validAction.HasRequired(va => va.Country)
                       .WithMany()
                       .HasForeignKey(va => va.CountryId);

            validAction.HasRequired(va => va.CaseType)
                       .WithMany()
                       .HasForeignKey(va => va.CaseTypeId);
        }

        static void ConfigureOpenAction(DbModelBuilder modelBuilder)
        {
            var openAction = modelBuilder.Entity<OpenAction>();
            openAction.Map(m => m.ToTable("OPENACTION"));

            openAction.HasKey(oa => new { oa.CaseId, oa.ActionId, oa.Cycle });

            openAction.HasRequired(oa => oa.Action)
                      .WithMany()
                      .HasForeignKey(oa => oa.ActionId);

            openAction.HasRequired(oa => oa.Case)
                      .WithMany(c => c.OpenActions)
                      .HasForeignKey(oa => oa.CaseId);

            openAction.HasRequired(oa => oa.Criteria)
                      .WithMany()
                      .HasForeignKey(oa => oa.CriteriaId);
        }

        static void ConfigureProperty(DbModelBuilder modelBuilder)
        {
            var property = modelBuilder.Entity<CaseProperty>();

            property.HasOptional(p => p.RenewalStatus)
                    .WithMany()
                    .HasForeignKey(p => p.RenewalStatusId);

            property.HasOptional(p => p.ApplicationBasis)
                    .WithMany()
                    .HasForeignKey(p => p.Basis);
        }

        static void ConfigureLocation(DbModelBuilder modelBuilder)
        {
            var caseLocation = modelBuilder.Entity<CaseLocation>();

            caseLocation.HasOptional(l => l.Name)
                        .WithMany()
                        .HasForeignKey(l => l.IssuedBy);

            modelBuilder.Entity<FileRequest>();

            modelBuilder.Entity<RfIdFileRequest>();

            modelBuilder.Entity<FileLocationOffice>();
        }

        static void ConfigureGlobalNameChange(DbModelBuilder modelBuilder)
        {
            var globalNameChange = modelBuilder.Entity<GlobalNameChangeRequest>();
            globalNameChange.Map(gnc => gnc.ToTable("CASENAMEREQUESTCASES"));
            globalNameChange.HasKey(gnc => new { gnc.CaseId, gnc.RequestNo });
        }

        [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
        static void ConfigureCase(DbModelBuilder modelBuilder)
        {
            var @case = modelBuilder.Entity<Case>();
            @case.Map(m => m.ToTable("CASES"));

            modelBuilder.Entity<CaseIndexes>()
                        .HasKey(ci => new { ci.GenericIndex, ci.CaseId, ci.Source });

            @case.HasRequired(c => c.PropertyType)
                 .WithMany()
                 .HasForeignKey(c => c.PropertyTypeId);

            @case.HasRequired(c => c.Country)
                 .WithMany()
                 .HasForeignKey(c => c.CountryId);

            @case.HasRequired(c => c.Type)
                 .WithMany()
                 .HasForeignKey(c => c.TypeId);

            @case.HasOptional(c => c.CaseStatus)
                 .WithMany()
                 .HasForeignKey(c => c.StatusCode);

            @case.HasOptional(c => c.Category)
                 .WithMany()
                 .HasForeignKey(c => new { c.TypeId, c.CategoryId });

            @case.HasOptional(c => c.ProfitCentre)
                 .WithMany()
                 .HasForeignKey(c => c.ProfitCentreCode);

            @case.HasOptional(c => c.SubType)
                 .WithMany()
                 .HasForeignKey(c => c.SubTypeId);

            @case.HasOptional(c => c.Family)
                 .WithMany()
                 .HasForeignKey(c => c.FamilyId);

            @case.HasOptional(c => c.Office)
                 .WithMany()
                 .HasForeignKey(c => c.OfficeId);

            @case.HasOptional(c => c.TypeOfMark)
                 .WithMany()
                 .HasForeignKey(c => c.TypeOfMarkId);

            @case.HasOptional(c => c.EntitySize)
                 .WithMany()
                 .HasForeignKey(c => c.EntitySizeId);

            @case.HasMany(c => c.CaseLocations)
                 .WithOptional()
                 .HasForeignKey(cl => cl.CaseId);

            @case.HasMany(c => c.FileRequests)
                 .WithOptional()
                 .HasForeignKey(cl => cl.CaseId);

            @case.HasMany(c => c.CaseListMemberships)
                 .WithOptional()
                 .HasForeignKey(clm => clm.CaseId);

            @case.HasMany(c => c.Activities)
                 .WithOptional()
                 .HasForeignKey(a => a.CaseId);

            @case.HasMany(c => c.CaseChecklists)
                 .WithOptional()
                 .HasForeignKey(cl => cl.CaseId);

            @case.HasMany(c => c.CaseDesignElements)
                 .WithOptional()
                 .HasForeignKey(cl => cl.CaseId);
        }

        static void ConfigureCaseName(DbModelBuilder modelBuilder)
        {
            var caseName = modelBuilder.Entity<CaseName>();
            caseName.HasOptional(c => c.Address)
                    .WithMany()
                    .HasForeignKey(m => m.AddressCode);

            caseName.HasOptional(c => c.NameVariant)
                    .WithMany()
                    .HasForeignKey(m => m.NameVariantId);

            caseName.HasOptional(c => c.CorrespondenceReceived)
                    .WithMany()
                    .Map(m => m.MapKey("CORRESPRECEIVED"));

            caseName.HasRequired(c => c.NameType)
                    .WithMany()
                    .HasForeignKey(c => c.NameTypeId);
        }

        static void ConfigureCaseFilePart(DbModelBuilder modelBuilder)
        {
            var caseFilePart = modelBuilder.Entity<CaseFilePart>();
            caseFilePart.Map(c => c.ToTable("FILEPART"))
                        .HasKey(fp => new { fp.CaseId, fp.FilePart });
        }

        static void ConfigureAddress(DbModelBuilder modelBuilder)
        {
            var address = modelBuilder.Entity<Address>();
            address.HasOptional(a => a.Country)
                   .WithMany()
                   .HasForeignKey(c => c.CountryId);
        }

        static void ConfigureActivityRequest(DbModelBuilder modelBuilder)
        {
            var activityRequest = modelBuilder.Entity<CaseActivityRequest>();

            activityRequest.Map(m => m.ToTable("ACTIVITYREQUEST"))
                           .HasKey(ar => new { ar.Id, ar.SqlUser });
        }

        static void ConfigureCaseActivityHistory(DbModelBuilder modelBuilder)
        {
            var caseActivityHistory = modelBuilder.Entity<CaseActivityHistory>();

            caseActivityHistory.Map(m => m.ToTable("ACTIVITYHISTORY"))
                               .HasKey(ah => new { ah.Id, ah.SqlUser });
        }

        public void ConfigureSanityCheckResults(DbModelBuilder modelBuilder)
        {
            var sanityCheckResult = modelBuilder.Entity<SanityCheckResult>();
            sanityCheckResult.HasRequired(_ => _.BackgroundProcess).WithMany()
                             .HasForeignKey(_ => _.ProcessId);

            sanityCheckResult.HasRequired(_ => _.Case).WithMany()
                             .HasForeignKey(_ => _.CaseId);
        }

        public void ConfigureExchangeRateVariations(DbModelBuilder modelBuilder)
        {
            var exchangeRateVariation = modelBuilder.Entity<ExchangeRateVariation>();
            exchangeRateVariation.HasOptional(_ => _.ExchangeRateSchedule).WithMany().HasForeignKey(_ => _.ExchScheduleId);
            exchangeRateVariation.HasOptional(_ => _.Currency).WithMany().HasForeignKey(_ => _.CurrencyCode);
            exchangeRateVariation.HasOptional(_ => _.CaseType).WithMany().HasForeignKey(_ => _.CaseTypeCode);
            exchangeRateVariation.HasOptional(_ => _.Country).WithMany().HasForeignKey(_ => _.CountryCode);
        }
    }
}