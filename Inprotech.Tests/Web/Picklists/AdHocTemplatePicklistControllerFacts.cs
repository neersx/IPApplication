using System;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Reminders;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class AdHocTemplatePicklistControllerFacts : FactBase
    {
        [Fact]
        public void ShouldCalledSearch()
        {
            var f = new AdHocTemplatePicklistControllerFixture(Db);

            var result = f.Subject.Search(null, string.Empty);

            Assert.Equal(null, result.Ids);
        }

        [Fact]
        public void ShouldGetAdhocTemplates()
        {
            var f = new AdHocTemplatePicklistControllerFixture(Db);

            new AlertTemplate { AlertMessage = Fixture.String(), AlertTemplateCode = Fixture.String() }.In(Db);
            new AlertTemplate { AlertMessage = Fixture.String(), AlertTemplateCode = Fixture.String() }.In(Db);

            var result = f.Subject.Search(new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.Equal(2, result.Data.Count());
        }

        [Fact]
        public void ShouldGetAdhocTemplatesBySearchText()
        {
            var f = new AdHocTemplatePicklistControllerFixture(Db);

            new AlertTemplate { AlertMessage = "Test adhoc template message", AlertTemplateCode = "AT" }.In(Db);
            new AlertTemplate { AlertMessage = Fixture.String(), AlertTemplateCode = "AS" }.In(Db);

            var result = f.Subject.Search(new CommonQueryParameters(), "adhoc");

            Assert.Equal(1, result.Data.Count());
            Assert.Equal("AT", ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].Code);
            Assert.Equal("Test adhoc template message", ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].Message);
        }

        [Fact]
        public void ShouldReturnDefaultSortAdhocTemplates()
        {
            var f = new AdHocTemplatePicklistControllerFixture(Db);

            new AlertTemplate { AlertMessage = Fixture.String(), AlertTemplateCode = "C" }.In(Db);
            new AlertTemplate { AlertMessage = Fixture.String(), AlertTemplateCode = "B" }.In(Db);
            new AlertTemplate { AlertMessage = Fixture.String(), AlertTemplateCode = "A" }.In(Db);

            var result = f.Subject.Search(new CommonQueryParameters());

            Assert.Equal(3, result.Data.Count());
            Assert.Equal("A", ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].Code);
        }

        [Fact]
        public void ShouldReturnSortedAdhocTemplatesByMessage()
        {
            var f = new AdHocTemplatePicklistControllerFixture(Db);

            new AlertTemplate { AlertMessage = "Message2", AlertTemplateCode = "C" }.In(Db);
            new AlertTemplate { AlertMessage = "Message1", AlertTemplateCode = "B" }.In(Db);
            new AlertTemplate { AlertMessage = "Message3", AlertTemplateCode = "A" }.In(Db);

            var result = f.Subject.Search(new CommonQueryParameters { SortBy = "Message" });

            Assert.Equal(3, result.Data.Count());
            Assert.Equal("B", ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].Code);
            Assert.Equal("Message1", ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].Message);
        }

        [Fact]
        public void ShouldGetAdhocTemplatesToCreateAdhocReminder()
        {
            var f = new AdHocTemplatePicklistControllerFixture(Db);

            new AlertTemplate { AlertMessage = "A", AlertTemplateCode = Fixture.String(), DailyFrequency = 4, DaysLead = 2, DeleteAlert = 5, StopAlert = 3, Importance = "9", NameTypeId = KnownNameTypes.Owner, Relationship = "CON", StaffId = 2 }.In(Db);
            new AlertTemplate { AlertMessage = Fixture.String(), AlertTemplateCode = Fixture.String(), MonthlyFrequency = Fixture.Short(), MonthsLead = Fixture.Short(), DeleteAlert = Fixture.Short(), StopAlert = Fixture.Short() }.In(Db);
            new Importance { Description = "Maximum", Level = "9" }.In(Db);
            new NameTypeBuilder { NameTypeCode = KnownNameTypes.Owner, Name = "Owner", PriorityOrder = 1 }.Build().In(Db);
            new NameRelation("CON", "Contact", "Contact For", 6, false, 0).In(Db);
            new NameBuilder(Db) { NameCode = "121", FirstName = "Mary", LastName = "S" }.Build().WithKnownId(2).In(Db);

            var result = f.Subject.Search(new CommonQueryParameters { SortBy = "Message" });
            var dayLead = ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].DaysLead;
            var dailyFrequency = ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].DailyFrequency;
            var stopAlert = ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].StopAlert;
            var deleteAlert = ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].DeleteAlert;
            var importanceLevel = ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].ImportanceLevel;
            var relationshipCode = ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].RelationshipValue.Code;
            var nameTypeCode = ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].NameTypeValue.Code;
            var name = ((AdHocTemplatePicklistController.AdHocTemplatePicklistItem[])result.Data)[0].AdhocResponsibleName.DisplayName;
            Assert.NotNull(result);
            Assert.Equal(2, result.Data.Count());
            Assert.Equal(Convert.ToInt16(2), dayLead);
            Assert.Equal(Convert.ToInt16(4), dailyFrequency);
            Assert.Equal(Convert.ToInt16(3), stopAlert);
            Assert.Equal(Convert.ToInt16(5), deleteAlert);
            Assert.Equal(9, importanceLevel);
            Assert.Equal("CON", relationshipCode);
            Assert.Equal(KnownNameTypes.Owner, nameTypeCode);
            Assert.Equal("S, Mary", name);
        }
    }

    public class AdHocTemplatePicklistControllerFixture : IFixture<AdHocTemplatePicklistController>
    {
        public AdHocTemplatePicklistControllerFixture(InMemoryDbContext db)
        {
            Subject = new AdHocTemplatePicklistController(db);
        }

        public AdHocTemplatePicklistController Subject { get; }
    }
}