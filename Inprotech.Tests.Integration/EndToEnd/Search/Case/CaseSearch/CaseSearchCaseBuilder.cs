using System;
using System.Data.Entity;
using System.Drawing;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.StandingInstructions;
using InprotechKaizen.Model.ValidCombinations;
using Action = InprotechKaizen.Model.Cases.Action;
using Image = InprotechKaizen.Model.Cases.Image;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    public class CaseSearchCaseBuilder : Builder
    {
        public CaseSearchCaseBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public SummaryData Build(string prefix = null, bool isExternalUser = false)
        {
            string userName = null;
            TestUser testUser = null;

            if (isExternalUser)
            {
                testUser = new Users().CreateExternalUser();
                userName = testUser.Username;
            }

            // create as a property case
            var @case = new CaseBuilder(DbContext).Create(prefix, true, userName);

            @case.Title = Fixture.String(5);

            var category = InsertWithRetry(() => new CaseCategory(@case.TypeId, Fixture.AlphaNumericString(2), Fixture.String(5)), (l, r) => l.CaseCategoryId.ToUpper() == r.CaseCategoryId.ToUpper());
            @case.CategoryId = category.CaseCategoryId;

            Insert(new ValidCategory { CountryId = @case.Country.Id, PropertyTypeId = @case.PropertyType.Code, CaseCategoryId = @case.CategoryId, CaseTypeId = @case.TypeId, CaseCategoryDesc = "v" + category.Name });

            var subType = InsertWithNewId(new SubType { Name = RandomString.Next(5) });
            @case.SubTypeId = subType.Code;
            Insert(new ValidSubType { SubtypeId = @case.SubTypeId, PropertyTypeId = @case.PropertyType.Code, CaseTypeId = @case.TypeId, CaseCategoryId = @case.CategoryId, CountryId = @case.Country.Id, SubTypeDescription = "v" + subType.Name });

            var officeTableCode = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.Office, Name = Fixture.String(5) });
            var office = InsertWithNewId(new Office(officeTableCode.Id, officeTableCode.Name));
            @case.Office = office;

            var fileLocation = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.FileLocation, Name = Fixture.String(5) });
            var caseLocation = InsertWithNewId(new CaseLocation(@case, fileLocation, Fixture.PastDate()) { BayNo = RandomString.Next(20) });
            @case.CaseLocations.Add(caseLocation);

            var entitySize = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.EntitySize, Name = Fixture.String(6) });
            @case.EntitySize = entitySize;

            var status = InsertWithNewId(new Status { Name = RandomString.Next(5), ExternalName = RandomString.Next(5), LiveFlag = 1, RegisteredFlag = 1 });
            @case.CaseStatus = status;

            var renewalStatus = InsertWithNewId(new Status { Name = "R" + RandomString.Next(5), ExternalName = "R" + RandomString.Next(5), LiveFlag = 1, RegisteredFlag = 1, RenewalFlag = 1 });
            var basis = InsertWithNewId(new ApplicationBasis { Name = RandomString.Next(5) });
            InsertWithNewId(new CaseProperty(@case, basis, renewalStatus));

            var instructor = @case.CaseNames.First(_ => _.NameTypeId == "I");

            // Renewal instruction
            var instructionType = DbContext.Set<InstructionType>().Include(_ => _.NameType).Single(_ => _.Code == "R");

            // requires renewal instructor
            Insert(new CaseName(@case, instructionType.NameType, instructor.Name, (short)(@case.CaseNames.Max(_ => _.Sequence) + 1)));
            var instruction = Insert(new Instruction { InstructionTypeCode = "R", Description = RandomString.Next(5) });
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

            var ceasedCountry = new Country("c1", "country1") { DateCeased = DateTime.Today.AddDays(-5), Type = "0" };
            DbContext.Set<Country>().Add(ceasedCountry);
            DbContext.SaveChanges();

            return new SummaryData
            {
                Case = @case,
                RenewalStatus = renewalStatus.Name,
                RenewalInstruction = instruction.Description,
                User = testUser,
                CeasedCountry = ceasedCountry
            };
        }

        public void SetupColumn(string columnLabel, int? groupId = null)
        {
            var globalDefaultPresentation = DbContext.Set<QueryPresentation>().Single(_ => _.ContextId == 2 && _.IsDefault && _.PresentationType == null);
            var presentationId = globalDefaultPresentation.Id;

            var qcc = DbContext.Set<QueryContextColumn>().Single(_ => _.GroupId == groupId && _.ContextId == 2 && _.QueryColumn.ColumnLabel.Equals(columnLabel));
            var columnId = qcc.ColumnId;

            var maxSequence = DbContext.Set<QueryContent>().Where(_ => _.PresentationId == presentationId && _.ContextId == 2).Max(_ => _.DisplaySequence);

            DbContext.Set<QueryContent>().Add(new QueryContent
            {
                PresentationId = presentationId,
                ColumnId = columnId,
                ContextId = 2,
                DisplaySequence = maxSequence
            });
            DbContext.SaveChanges();
        }

        public class SummaryData
        {
            public InprotechKaizen.Model.Cases.Case Case { get; internal set; }
            public string RenewalStatus { get; internal set; }
            public string RenewalInstruction { get; internal set; }
            public TestUser User { get; internal set; }
            public Country CeasedCountry { get; set; }
        }
    }
}