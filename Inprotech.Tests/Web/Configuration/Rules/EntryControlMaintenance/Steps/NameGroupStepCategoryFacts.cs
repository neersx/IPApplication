using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class NameGroupStepCategoryFacts : FactBase
    {
        [Theory]
        [InlineData("random")]
        [InlineData(null)]
        public void ReturnsNullIfNotFound(string filterValue)
        {
            var value = filterValue == null ? (short?) null : Fixture.Short();

            var filter = new TopicControlFilter("NameGroupKey", value.ToString());

            var result = CreateSubject().Get(filter);

            Assert.Equal("nameTypeGroup", result.CategoryCode);
            Assert.Null(result.CategoryValue);
        }

        NameGroupStepCategory CreateSubject()
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            return new NameGroupStepCategory(Db, preferredCultureResolver);
        }

        [Fact]
        public void CategoryTypeIsNameGroup()
        {
            Assert.Equal("nameTypeGroup", CreateSubject().CategoryType);
        }

        [Fact]
        public void ReturnsValueIfFound()
        {
            var nameGroup = new NameGroupBuilder().Build().In(Db);

            var filter = new TopicControlFilter("NameGroupKey", nameGroup.Id.ToString());

            var result = CreateSubject().Get(filter);

            var resultModel = (StepPicklistModel<short>) result.CategoryValue;

            Assert.Equal("nameTypeGroup", result.CategoryCode);
            Assert.Equal(nameGroup.Id, resultModel.Key);
            Assert.Equal(nameGroup.Value, resultModel.Value);
        }
    }
}