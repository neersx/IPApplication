using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class ChecklistTypeStepCategoryFacts : FactBase
    {
        [Theory]
        [InlineData("random")]
        [InlineData(null)]
        public void ReturnsNullIfNotFound(string filterValue)
        {
            var criteria = new CriteriaBuilder().Build();

            var value = filterValue == null ? (int?) null : Fixture.Short();

            var filter = new TopicControlFilter("ChecklistTypeKey", value.ToString());

            var result = CreateSubject().Get(filter, criteria);

            Assert.Equal("checklist", result.CategoryCode);
            Assert.Null(result.CategoryValue);
        }

        ChecklistTypeStepCategory CreateSubject(params Checklist[] types)
        {
            var checklists = Substitute.For<IChecklists>();
            checklists.Get(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<short?>())
                      .Returns(types ?? Enumerable.Empty<Checklist>());

            return new ChecklistTypeStepCategory(checklists);
        }

        [Fact]
        public void CategoryTypeIsChecklist()
        {
            Assert.Equal("checklist", CreateSubject().CategoryType);
        }

        [Fact]
        public void ReturnsValueIfFound()
        {
            var criteria = new CriteriaBuilder().Build();

            var checklistTypeKey = Fixture.Short();

            var checklist = Fixture.String();

            var baseChecklistDescription = Fixture.String();

            var filter = new TopicControlFilter("ChecklistTypeKey", checklistTypeKey.ToString());

            var result = CreateSubject(new Checklist
            {
                Id = checklistTypeKey,
                Description = checklist,
                BaseDescription = baseChecklistDescription
            }).Get(filter, criteria);

            var resultModel = (StepPicklistModel<short>) result.CategoryValue;

            Assert.Equal("checklist", result.CategoryCode);
            Assert.Equal(checklistTypeKey, resultModel.Key);
            Assert.Equal(checklist, resultModel.DisplayValue);
            Assert.Equal(baseChecklistDescription, resultModel.Value);
        }
    }
}