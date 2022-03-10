using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class ActionStepCategoryFacts : FactBase
    {
        [Theory]
        [InlineData("random")]
        [InlineData(null)]
        public void ReturnsNullIfNotFound(string filterValue)
        {
            var criteria = new CriteriaBuilder().Build();

            var value = filterValue == null ? (int?) null : Fixture.Short();

            var filter = new TopicControlFilter("CreateActionKey", value.ToString());

            var result = CreateSubject().Get(filter, criteria);

            Assert.Equal("action", result.CategoryCode);
            Assert.Null(result.CategoryValue);
        }

        ActionStepCategory CreateSubject(params ActionData[] action)
        {
            var result = action.AsEnumerable();

            var actions = Substitute.For<IActions>();
            actions.Get(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                   .Returns(result);

            return new ActionStepCategory(actions);
        }

        [Fact]
        public void CategoryTypeIsAction()
        {
            Assert.Equal("action", CreateSubject().CategoryType);
        }

        [Fact]
        public void ReturnsValueIfFound()
        {
            var criteria = new CriteriaBuilder().Build();

            var actionKey = Fixture.String();

            var actionName = Fixture.String();

            var baseActionName = Fixture.String();

            var filter = new TopicControlFilter("CreateActionKey", actionKey);

            var result = CreateSubject(new ActionData
            {
                Code = actionKey,
                Name = actionName,
                BaseName = baseActionName
            }).Get(filter, criteria);

            var resultModel = (StepPicklistModel<string>) result.CategoryValue;

            Assert.Equal("action", result.CategoryCode);
            Assert.Equal(actionKey, resultModel.Key);
            Assert.Equal(actionName, resultModel.DisplayValue);
            Assert.Equal(baseActionName, resultModel.Value);
        }
    }
}