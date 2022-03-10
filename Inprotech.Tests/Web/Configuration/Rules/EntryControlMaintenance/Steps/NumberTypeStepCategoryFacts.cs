using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class NumberTypeStepCategoryFacts : FactBase
    {
        [Theory]
        [InlineData("random")]
        [InlineData(null)]
        public void ReturnsNullIfNotFound(string filterValue)
        {
            var value = filterValue == null ? null : Fixture.String();

            var filter = new TopicControlFilter("NumberTypeKey", value);

            var result = CreateSubject().Get(filter);

            Assert.Equal("numberType", result.CategoryCode);
            Assert.Null(result.CategoryValue);
        }

        NumberTypeStepCategory CreateSubject()
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            return new NumberTypeStepCategory(Db, preferredCultureResolver);
        }

        [Fact]
        public void CategoryTypeIsNumberType()
        {
            Assert.Equal("numberType", CreateSubject().CategoryType);
        }

        [Fact]
        public void ReturnsValueIfFound()
        {
            var textType = new NumberTypeBuilder
            {
                Code = Fixture.String()
            }.Build().In(Db);

            var filter = new TopicControlFilter("NumberTypeKey", textType.NumberTypeCode);

            var result = CreateSubject().Get(filter);

            var resultModel = (StepPicklistModel<string>) result.CategoryValue;

            Assert.Equal("numberType", result.CategoryCode);
            Assert.Equal(textType.NumberTypeCode, resultModel.Key);
            Assert.Equal(textType.Name, resultModel.Value);
        }
    }
}