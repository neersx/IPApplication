using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class TextTypeStepCategoryFacts : FactBase
    {
        [Theory]
        [InlineData("random")]
        [InlineData(null)]
        public void ReturnsNullIfNotFound(string filterValue)
        {
            var value = filterValue == null ? null : Fixture.String();

            var filter = new TopicControlFilter("TextTypeKey", value);

            var result = CreateSubject().Get(filter);

            Assert.Equal("textType", result.CategoryCode);
            Assert.Null(result.CategoryValue);
        }

        TextTypeStepCategory CreateSubject()
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            return new TextTypeStepCategory(Db, preferredCultureResolver);
        }

        [Fact]
        public void CategoryTypeIsTextType()
        {
            Assert.Equal("textType", CreateSubject().CategoryType);
        }

        [Fact]
        public void ReturnsValueIfFound()
        {
            var textType = new TextTypeBuilder
            {
                Id = Fixture.String()
            }.Build().In(Db);

            var filter = new TopicControlFilter("TextTypeKey", textType.Id);

            var result = CreateSubject().Get(filter);

            var resultModel = (StepPicklistModel<string>) result.CategoryValue;

            Assert.Equal("textType", result.CategoryCode);
            Assert.Equal(textType.Id, resultModel.Key);
            Assert.Equal(textType.TextDescription, resultModel.Value);
        }
    }
}