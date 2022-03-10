using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class CountryFlagStepCategoryFacts : FactBase
    {
        [Theory]
        [InlineData("random")]
        [InlineData(null)]
        public void ReturnsNullIfNotFound(string filterValue)
        {
            var country = new CountryBuilder().Build().In(Db);

            var criteria = new CriteriaBuilder
            {
                Country = country
            }.Build().In(Db);

            var value = filterValue == null ? (int?) null : Fixture.Short();

            var filter = new TopicControlFilter("designationStage", value.ToString());

            var result = CreateSubject().Get(filter, criteria);

            Assert.Equal("designationStage", result.CategoryCode);
            Assert.Null(result.CategoryValue);
        }

        CountryFlagStepCategory CreateSubject()
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            return new CountryFlagStepCategory(Db, preferredCultureResolver);
        }

        [Fact]
        public void CategoryTypeIsCountryFlag()
        {
            Assert.Equal("designationStage", CreateSubject().CategoryType);
        }

        [Fact]
        public void ReturnsValueIfFound()
        {
            var country = new CountryBuilder().Build().In(Db);

            var criteria = new CriteriaBuilder
            {
                Country = country
            }.Build().In(Db);

            var countryFlag = new CountryFlagBuilder
            {
                Country = country
            }.Build().In(Db);

            var filter = new TopicControlFilter("designationStage", countryFlag.FlagNumber.ToString());

            var result = CreateSubject().Get(filter, criteria);

            var resultModel = (StepPicklistModel<int>) result.CategoryValue;

            Assert.Equal("designationStage", result.CategoryCode);
            Assert.Equal(countryFlag.FlagNumber, resultModel.Key);
            Assert.Equal(countryFlag.Name, resultModel.Value);
        }
    }
}