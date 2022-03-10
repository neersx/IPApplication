using System;
using System.Data.Entity;
using System.Drawing;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.StandingInstructions;
using InprotechKaizen.Model.ValidCombinations;
using Action = InprotechKaizen.Model.Cases.Action;
using Image = InprotechKaizen.Model.Cases.Image;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    internal class CaseBuilder : Builder
    {
        public CaseBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public bool WithDebtor { private get; set; }

        public Case Create(string prefix = null, bool? propertyCase = false, string userName = null, Country country = null, PropertyType propertyType = null, bool withDebtor = true, bool isStaffSignatoryRequiredPrefix = false, Name staffModel = null)
        {
            if (prefix == null)
            {
                prefix = DefaultPrefix;
            }

            country ??= InsertWithNewAlphaNumericId(new Country
            {
                Name = prefix + "country",
                Type = "0"
            });

            CaseType caseType;
            if (propertyCase.GetValueOrDefault())
            {
                caseType = DbContext.Set<CaseType>().Single(_ => _.Code == "A");
            }
            else
            {
                caseType = InsertWithNewId(new CaseType
                {
                    Name = prefix + "caseType"
                }, x => x.Code, useAlphaNumeric: true);
            }

            propertyType ??= InsertWithNewId(new PropertyType
            {
                Name = prefix + "propertyType"
            }, x => x.Code);

            WithDebtor = withDebtor;

            var @case = InsertWithNewId(new Case
            {
                Irn = prefix + "irn",
                Country = country,
                CountryId = country.Id,
                Type = caseType,
                PropertyType = propertyType,
                PropertyTypeId = propertyType.Code,
                IpoDelay = 10,
                ApplicantDelay = 12,
                LocalClasses = "L1",
                IntClasses = "I1",
                Title = Fixture.String(10)
            });

            var instructor = userName == null ? new NameBuilder(DbContext).CreateClientIndividual() :
                DbContext.Set<User>().First(_ => _.UserName == userName).Name;
            var instructorNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Instructor);
            @case.CaseNames.Add(new CaseName(@case, instructorNameType, instructor, 0));

            var ownerNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Owner);
            var owner = new NameBuilder(DbContext).CreateClientIndividual();
            @case.CaseNames.Add(new CaseName(@case, ownerNameType, owner, 1));
            
            var staffNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.StaffMember);
            if (staffModel == null)
            {
                Name staff = null;
                staff = isStaffSignatoryRequiredPrefix ? new NameBuilder(DbContext).CreateStaff(prefix, email: "staff@org.com") : new NameBuilder(DbContext).CreateStaff(email: "staff@org.com");
                @case.CaseNames.Add(new CaseName(@case, staffNameType, staff, 2));

            }
            else
            {
                @case.CaseNames.Add(new CaseName(@case, staffNameType, staffModel, 0));
            }

            if (isStaffSignatoryRequiredPrefix)
            {
                var signatoryNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Signatory);
                var signatory = new NameBuilder(DbContext).CreateStaff(prefix, email: "signatory@org.com");
                @case.CaseNames.Add(new CaseName(@case, signatoryNameType, signatory, 0));
            }
            else
            {
                var signatoryNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Signatory);
                var signatory = new NameBuilder(DbContext).CreateStaff(email: "signatory@org.com");
                @case.CaseNames.Add(new CaseName(@case, signatoryNameType, signatory, 0));
            }

            if (WithDebtor)
            {
                var debtorNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);
                var debtor = new NameBuilder(DbContext).CreateClientIndividual();
                @case.CaseNames.Add(new CaseName(@case, debtorNameType, debtor, 4));
            }

            if (!DbContext.Set<ValidProperty>().Any(_ => _.CountryId == country.Id && _.PropertyTypeId == propertyType.Code))
            {
                // required for case search
                Insert(new ValidProperty { CountryId = country.Id, PropertyTypeId = propertyType.Code, PropertyName = "v" + propertyType.Name });
            }

            Insert(new CaseEvent(@case.Id, (int)KnownEvents.InstructionsReceivedDateForNewCase, 1) { EventDueDate = DateTime.Today.AddDays(-30), IsOccurredFlag = 1 });

            return @case;
        }

        public SummaryData CreateWithSummaryData(string prefix = null, bool isExternalUser = false)
        {
            string userName = null;
            TestUser testUser = null;

            if (isExternalUser)
            {
                testUser = new Users().CreateExternalUser();
                userName = testUser.Username;
            }
            // create as a property case
            var @case = Create(prefix, true, userName);

            @case.Title = Fixture.String(5);

            var category = InsertWithRetry(() => new CaseCategory(@case.TypeId, Fixture.AlphaNumericString(2), Fixture.String(5)), (l, r) => l.CaseCategoryId.ToUpper() == r.CaseCategoryId.ToUpper());
            @case.CategoryId = category.CaseCategoryId;

            Insert(new ValidCategory { CountryId = @case.Country.Id, PropertyTypeId = @case.PropertyType.Code, CaseCategoryId = @case.CategoryId, CaseTypeId = @case.TypeId, CaseCategoryDesc = "v" + category.Name });

            var subType = InsertWithNewId(new SubType { Name = Fixture.String(5) });
            @case.SubTypeId = subType.Code;
            Insert(new ValidSubType { SubtypeId = @case.SubTypeId, PropertyTypeId = @case.PropertyType.Code, CaseTypeId = @case.TypeId, CaseCategoryId = @case.CategoryId, CountryId = @case.Country.Id, SubTypeDescription = "v" + subType.Name });

            var officeTableCode = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.Office, Name = Fixture.String(5) });
            var office = InsertWithNewId(new Office(officeTableCode.Id, officeTableCode.Name));
            @case.Office = office;

            var fileLocation = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.FileLocation, Name = Fixture.String(5) });

            var caseLocation = InsertWithNewId(new CaseLocation(@case, fileLocation, Fixture.PastDate()) { BayNo = Fixture.String(20) });
            @case.CaseLocations.Add(caseLocation);

            var status = InsertWithNewId(new Status { Name = Fixture.String(5), ExternalName = Fixture.String(5), LiveFlag = 1, RegisteredFlag = 1 });
            @case.CaseStatus = status;

            var renewalStatus = InsertWithNewId(new Status { Name = "R" + Fixture.String(5), ExternalName = "R" + Fixture.String(5), LiveFlag = 1, RegisteredFlag = 1, RenewalFlag = 1 });
            var basis = InsertWithNewId(new ApplicationBasis { Name = Fixture.String(5) });
            InsertWithNewId(new CaseProperty(@case, basis, renewalStatus));

            var instructor = @case.CaseNames.First(_ => _.NameTypeId == "I");

            // Renewal instruction
            var instructionType = DbContext.Set<InstructionType>().Include(_ => _.NameType).Single(_ => _.Code == "R");

            // requires renewal instructor
            Insert(new CaseName(@case, instructionType.NameType, instructor.Name, (short)(@case.CaseNames.Max(_ => _.Sequence) + 1)));
            var instruction = Insert(new Instruction { InstructionTypeCode = "R", Description = Fixture.String(5) });
            Insert(new NameInstruction { InstructionId = instruction.Id, CaseId = @case.Id, Id = instructor.NameId });

            var pngImage = Fixture.Image(50, 50, Color.Blue);
            var image = InsertWithNewId(new Image { ImageData = pngImage });
            var imageType = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CaseViewSummaryImageType).StringValue;
            Insert(new CaseImage(@case, image.Id, 0, int.Parse(imageType)));

            var mainRenewalActionSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
            var renewalAction = DbContext.Set<Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
            var criticalDatesSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
            var criticalDatesCriteria = DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

            Insert(new OpenAction(renewalAction, @case, 1, null, criticalDatesCriteria, true));
            Insert(new CaseEvent(@case.Id, (int)KnownEvents.NextRenewalDate, 1) { EventDueDate = DateTime.Today.AddDays(-1), IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id });

            DbContext.SaveChanges();

            return new SummaryData
            {
                Case = @case,
                RenewalStatus = renewalStatus.Name,
                RenewalInstruction = instruction.Description,
                User = testUser
            };
        }
        
        public SummaryData CreateWithSummaryDataWithoutRenewalDetails(string prefix = null, bool isExternalUser = false, Name staffModel = null)
        {
            string userName = null;
            TestUser testUser = null;

            if (isExternalUser)
            {
                testUser = new Users().CreateExternalUser();
                userName = testUser.Username;
            }
            // create as a property case
            var @case = Create(prefix, true, userName, isStaffSignatoryRequiredPrefix: true, staffModel: staffModel);

            @case.Title = Fixture.String(5);

            var category = InsertWithRetry(() => new CaseCategory(@case.TypeId, Fixture.AlphaNumericString(2), Fixture.String(5)), (l, r) => l.CaseCategoryId.ToUpper() == r.CaseCategoryId.ToUpper());
            @case.CategoryId = category.CaseCategoryId;

            Insert(new ValidCategory { CountryId = @case.Country.Id, PropertyTypeId = @case.PropertyType.Code, CaseCategoryId = @case.CategoryId, CaseTypeId = @case.TypeId, CaseCategoryDesc = "v" + category.Name });

            var subType = InsertWithNewId(new SubType { Name = Fixture.String(5) });
            @case.SubTypeId = subType.Code;
            Insert(new ValidSubType { SubtypeId = @case.SubTypeId, PropertyTypeId = @case.PropertyType.Code, CaseTypeId = @case.TypeId, CaseCategoryId = @case.CategoryId, CountryId = @case.Country.Id, SubTypeDescription = "v" + subType.Name });

            var officeTableCode = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.Office, Name = Fixture.String(5) });
            var office = InsertWithNewId(new Office(officeTableCode.Id, officeTableCode.Name));
            @case.Office = office;

            var fileLocation = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.FileLocation, Name = Fixture.String(5) });

            var caseLocation = InsertWithNewId(new CaseLocation(@case, fileLocation, Fixture.PastDate()) { BayNo = Fixture.String(20) });
            @case.CaseLocations.Add(caseLocation);

            var status = InsertWithNewId(new Status { Name = Fixture.String(5), ExternalName = Fixture.String(5), LiveFlag = 1, RegisteredFlag = 1 });
            @case.CaseStatus = status;

            var pngImage = Fixture.Image(50, 50, Color.Blue);
            var image = InsertWithNewId(new Image { ImageData = pngImage });
            var imageType = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CaseViewSummaryImageType).StringValue;
            Insert(new CaseImage(@case, image.Id, 0, int.Parse(imageType)));

            var mainRenewalActionSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
            var renewalAction = DbContext.Set<Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
            var criticalDatesSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
            var criticalDatesCriteria = DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

            Insert(new OpenAction(renewalAction, @case, 1, null, criticalDatesCriteria, true));
            Insert(new CaseEvent(@case.Id, (int)KnownEvents.NextRenewalDate, 1) { EventDueDate = DateTime.Today.AddDays(-1), IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id, EmployeeNo = staffModel?.Id });

            DbContext.SaveChanges();

            return new SummaryData
            {
                Case = @case,
                User = testUser
            };
        }

        public class SummaryData
        {
            public Case Case { get; internal set; }
            public string RenewalStatus { get; internal set; }
            public string RenewalInstruction { get; internal set; }
            public TestUser User { get; internal set; }
        }
    }
}