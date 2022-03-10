using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class CaseRelationStepCategoryFacts : FactBase
    {
        [Theory]
        [InlineData("random")]
        [InlineData(null)]
        public void ReturnsNullIfNotFound(string filterValue)
        {
            var criteria = new CriteriaBuilder().Build();

            var value = filterValue == null ? (int?) null : Fixture.Short();

            var filter = new TopicControlFilter("CaseRelationKey", value.ToString());

            var result = CreateSubject().Get(filter, criteria);

            Assert.Equal("relationship", result.CategoryCode);
            Assert.Null(result.CategoryValue);
        }

        CaseRelationStepCategory CreateSubject(params Relationship[] types)
        {
            var relationships = Substitute.For<IRelationships>();
            relationships.Get(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .Returns(types ?? Enumerable.Empty<Relationship>());

            return new CaseRelationStepCategory(relationships);
        }

        [Fact]
        public void CategoryTypeIsRelationship()
        {
            Assert.Equal("relationship", CreateSubject().CategoryType);
        }

        [Fact]
        public void ReturnsValueIfFound()
        {
            var criteria = new CriteriaBuilder().Build();

            var relationshipKey = Fixture.String();

            var relationship = Fixture.String();

            var baseRelationshipDescription = Fixture.String();

            var filter = new TopicControlFilter("CaseRelationKey", relationshipKey);

            var result = CreateSubject(new Relationship
            {
                Id = relationshipKey,
                Description = relationship,
                BaseDescription = baseRelationshipDescription
            }).Get(filter, criteria);

            var resultModel = (StepPicklistModel<string>) result.CategoryValue;

            Assert.Equal("relationship", result.CategoryCode);
            Assert.Equal(relationshipKey, resultModel.Key);
            Assert.Equal(relationship, resultModel.DisplayValue);
            Assert.Equal(baseRelationshipDescription, resultModel.Value);
        }
    }
}