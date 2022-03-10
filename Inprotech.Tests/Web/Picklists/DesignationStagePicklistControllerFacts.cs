using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class DesignationStagePicklistControllerFacts : FactBase
    {
        DesignationStagePicklistController CreateSubject()
        {
            var cultureResolver = Substitute.For<IPreferredCultureResolver>();
            return new DesignationStagePicklistController(Db, cultureResolver);
        }

        [Fact]
        public void ReturnsDesignatedStagesContainingSearchString()
        {
            var pct = new CountryBuilder().Build().In(Db);

            new CountryFlagBuilder {Country = pct, FlagName = "abc"}.Build().In(Db);

            new CountryFlagBuilder {Country = pct, FlagName = "def"}.Build().In(Db);

            new CountryFlagBuilder {Country = pct, FlagName = "bd"}.Build().In(Db);

            var subject = CreateSubject();

            var r = subject.Get(jurisdictionId: pct.Id, search: "b")
                           .Data.Cast<DesignationStagePicklistController.DesignationStage>()
                           .ToArray();

            Assert.Equal(2, r.Count());

            Assert.Contains(r, _ => _.Value == "abc");
            Assert.Contains(r, _ => _.Value == "bd");
        }

        [Fact]
        public void ReturnsDesignationStagesForTheGivenJurisdiction()
        {
            var pct = new CountryBuilder().Build().In(Db);

            var madrid = new CountryBuilder().Build().In(Db);

            var registered = new CountryFlagBuilder {Country = pct}.Build().In(Db);

            var abandon = new CountryFlagBuilder {Country = pct}.Build().In(Db);

            new CountryFlagBuilder {Country = madrid}.Build().In(Db);

            var subject = CreateSubject();

            var r = subject.Get(jurisdictionId: pct.Id)
                           .Data.Cast<DesignationStagePicklistController.DesignationStage>()
                           .ToArray();

            Assert.Equal(2, r.Count());

            Assert.Contains(r, _ => _.Key == registered.FlagNumber);
            Assert.Contains(r, _ => _.Key == abandon.FlagNumber);
        }

        [Fact]
        public void ReturnsEmptyIfJurisdictionsNotProvided()
        {
            var pct = new CountryBuilder().Build().In(Db);

            new CountryFlagBuilder {Country = pct}.Build().In(Db);

            new CountryFlagBuilder {Country = pct}.Build().In(Db);

            var subject = CreateSubject();

            var r = subject.Get() /* no jurisdictions */
                           .Data.Cast<DesignationStagePicklistController.DesignationStage>()
                           .ToArray();

            Assert.Empty(r);
        }

        [Fact]
        public void ReturnsExactMatchEntry()
        {
            var pct = new CountryBuilder().Build().In(Db);

            new CountryFlagBuilder {Country = pct, FlagName = "abc"}.Build().In(Db);

            new CountryFlagBuilder {Country = pct, FlagName = "def"}.Build().In(Db);

            new CountryFlagBuilder {Country = pct, FlagName = "bd"}.Build().In(Db);

            var subject = CreateSubject();

            var r = subject.Get(jurisdictionId: pct.Id, search: "abc")
                           .Data.Cast<DesignationStagePicklistController.DesignationStage>()
                           .ToArray();

            Assert.Equal("abc", r.Single().Value);
        }

        [Fact]
        public void ReturnsJurisdictionsInOrderOfTheDefinedStage()
        {
            var pct = new CountryBuilder().Build().In(Db);

            var laterStage = new CountryFlagBuilder {Country = pct, FlagNumber = 64}.Build().In(Db);

            var earlierStage = new CountryFlagBuilder {Country = pct, FlagNumber = 32}.Build().In(Db);

            var subject = CreateSubject();

            var r = subject.Get(jurisdictionId: pct.Id)
                           .Data.Cast<DesignationStagePicklistController.DesignationStage>()
                           .ToArray();

            Assert.Equal(2, r.Count());

            Assert.Equal(earlierStage.FlagNumber, r.First().Key);
            Assert.Equal(laterStage.FlagNumber, r.Last().Key);
        }
    }
}