using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class NameTypeStepCategoryFacts : FactBase
    {
        [Theory]
        [InlineData("random")]
        [InlineData(null)]
        public void ReturnsNullIfNotFound(string filterValue)
        {
            var value = filterValue == null ? null : Fixture.String();

            var filter = new TopicControlFilter("NameTypeKey", value);

            var result = CreateSubject().Get(filter);

            Assert.Equal("nameType", result.CategoryCode);
            Assert.Null(result.CategoryValue);
        }

        NameTypeStepCategory CreateSubject()
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            return new NameTypeStepCategory(Db, preferredCultureResolver);
        }

        [Fact]
        public void CategoryTypeIsNameType()
        {
            Assert.Equal("nameType", CreateSubject().CategoryType);
        }

        [Fact]
        public void ReturnsValueIfFound()
        {
            var nameType = new NameTypeBuilder().Build().In(Db);

            var filter = new TopicControlFilter("NameTypeKey", nameType.NameTypeCode);

            var result = CreateSubject().Get(filter);

            var resultModel = (StepPicklistModel<int>) result.CategoryValue;

            Assert.Equal("nameType", result.CategoryCode);
            Assert.Equal(nameType.NameTypeCode, resultModel.Code);
            Assert.Equal(nameType.Id, resultModel.Key);
            Assert.Equal(nameType.Name, resultModel.Value);
        }
    }
}