using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Configuration.Screens;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance.Steps
{
    public class FlattenStepEqualityComparerFacts
    {
        public class TopicControlComparison
        {
            readonly FlattenTopicEqualityComparer _subject = new FlattenTopicEqualityComparer();

            [Fact]
            public void MatchByNameOnly()
            {
                var name = Fixture.String();

                var tc1 = TopicControlBuilder.For(name).Build();
                var tc2 = TopicControlBuilder.For(name).Build();

                tc1.Title = Fixture.String();
                tc1.ScreenTip = Fixture.String();
                tc1.RowPosition = Fixture.Short();
                tc1.IsInherited = false;
                tc1.IsMandatory = true;

                tc2.Title = Fixture.String();
                tc2.ScreenTip = Fixture.String();
                tc2.RowPosition = Fixture.Short();
                tc2.IsInherited = true;
                tc2.IsMandatory = false;

                Assert.True(_subject.Equals(tc1, tc2), "Should only match on name when filters are both null");
                Assert.True(_subject.Equals(tc1, tc1));
                Assert.True(_subject.Equals(tc2, tc2));
                Assert.False(ReferenceEquals(tc1, tc2));
            }

            [Fact]
            public void MatchNameWithBothFilters()
            {
                var name = Fixture.String();
                var filterName1 = Fixture.String();
                var filterValue1 = Fixture.String();
                var filterName2 = Fixture.String();
                var filterValue2 = Fixture.String();

                var tc1 = TopicControlBuilder.For(name, new TopicControlFilter(filterName1, filterValue1), new TopicControlFilter(filterName2, filterValue2)).Build();
                var tc2 = TopicControlBuilder.For(name, new TopicControlFilter(filterName1, filterValue1), new TopicControlFilter(filterName2, filterValue2)).Build();

                tc1.Title = Fixture.String();
                tc1.ScreenTip = Fixture.String();
                tc1.RowPosition = Fixture.Short();
                tc1.IsInherited = false;
                tc1.IsMandatory = true;

                tc2.Title = Fixture.String();
                tc2.ScreenTip = Fixture.String();
                tc2.RowPosition = Fixture.Short();
                tc2.IsInherited = true;
                tc2.IsMandatory = false;

                Assert.True(_subject.Equals(tc1, tc2), "Should only match on name and both filters");
                Assert.True(_subject.Equals(tc1, tc1));
                Assert.True(_subject.Equals(tc2, tc2));

                Assert.False(ReferenceEquals(tc1, tc2));
                Assert.False(ReferenceEquals(tc1.Filters.First(), tc2.Filters.First()));
                Assert.False(ReferenceEquals(tc1.Filters.Last(), tc2.Filters.Last()));
            }

            [Fact]
            public void MatchNameWithSingleFilter()
            {
                var name = Fixture.String();
                var filterName = Fixture.String();
                var filterValue = Fixture.String();

                var tc1 = TopicControlBuilder.For(name, new TopicControlFilter(filterName, filterValue)).Build();
                var tc2 = TopicControlBuilder.For(name, new TopicControlFilter(filterName, filterValue)).Build();

                tc1.Title = Fixture.String();
                tc1.ScreenTip = Fixture.String();
                tc1.RowPosition = Fixture.Short();
                tc1.IsInherited = false;
                tc1.IsMandatory = true;

                tc2.Title = Fixture.String();
                tc2.ScreenTip = Fixture.String();
                tc2.RowPosition = Fixture.Short();
                tc2.IsInherited = true;
                tc2.IsMandatory = false;

                Assert.True(_subject.Equals(tc1, tc2), "Should match on name and the provided filter");
                Assert.True(_subject.Equals(tc1, tc1));
                Assert.True(_subject.Equals(tc2, tc2));

                Assert.False(ReferenceEquals(tc1, tc2));
                Assert.False(ReferenceEquals(tc1.Filters.Single(), tc2.Filters.Single()));
            }

            [Fact]
            public void ReturnFalseWhenFilterNameDontMatch()
            {
                var name = Fixture.String();
                var filterValue = Fixture.String();

                var tc1 = TopicControlBuilder.For(name, new TopicControlFilter(Fixture.String(), filterValue)).Build();
                var tc2 = TopicControlBuilder.For(name, new TopicControlFilter(Fixture.String(), filterValue)).Build();

                Assert.False(_subject.Equals(tc1, tc2));
            }

            [Fact]
            public void ReturnFalseWhenFilterValueDontMatch()
            {
                var name = Fixture.String();
                var filterName = Fixture.String();

                var tc1 = TopicControlBuilder.For(name, new TopicControlFilter(filterName, Fixture.String())).Build();
                var tc2 = TopicControlBuilder.For(name, new TopicControlFilter(filterName, Fixture.String())).Build();

                Assert.False(_subject.Equals(tc1, tc2));
            }

            [Fact]
            public void ReturnFalseWhenNameDontMatch()
            {
                var tc1 = TopicControlBuilder.For(Fixture.String()).Build();
                var tc2 = TopicControlBuilder.For(Fixture.String()).Build();

                Assert.False(_subject.Equals(tc1, tc2));
            }
        }

        public class StepDeltaComparison
        {
            readonly FlattenTopicEqualityComparer _subject = new FlattenTopicEqualityComparer();

            [Fact]
            public void MatchByNameOnly()
            {
                var name = Fixture.String();
                var type = Fixture.String();

                var s1 = new StepDelta(name, type);
                var s2 = new StepDelta(name, type);

                s1.ScreenTip = Fixture.String();
                s1.Title = Fixture.String();
                s1.IsMandatory = false;

                s2.ScreenTip = Fixture.String();
                s2.Title = Fixture.String();
                s2.IsMandatory = true;

                Assert.True(_subject.Equals(s1, s2), "Should only match on name when filters are both null");
                Assert.True(_subject.Equals(s1, s1));
                Assert.True(_subject.Equals(s2, s2));
                Assert.False(ReferenceEquals(s1, s2));
            }

            [Fact]
            public void MatchNameWithBothFilters()
            {
                var name = Fixture.String();
                var type = Fixture.String();
                var filterName1 = Fixture.String();
                var filterValue1 = Fixture.String();
                var filterName2 = Fixture.String();
                var filterValue2 = Fixture.String();

                var s1 = new StepDelta(name, type, filterName1, filterValue1, filterName2, filterValue2);
                var s2 = new StepDelta(name, type, filterName1, filterValue1, filterName2, filterValue2);

                s1.ScreenTip = Fixture.String();
                s1.Title = Fixture.String();
                s1.IsMandatory = false;

                s2.ScreenTip = Fixture.String();
                s2.Title = Fixture.String();
                s2.IsMandatory = true;

                Assert.True(_subject.Equals(s1, s2), "Should match on name and both filters");
                Assert.True(_subject.Equals(s1, s1));
                Assert.True(_subject.Equals(s2, s2));

                Assert.False(ReferenceEquals(s1, s2));
                Assert.False(ReferenceEquals(s1.Categories.First(), s2.Categories.First()));
                Assert.False(ReferenceEquals(s1.Categories.Last(), s2.Categories.Last()));
            }

            [Fact]
            public void MatchNameWithSingleFilter()
            {
                var name = Fixture.String();
                var type = Fixture.String();
                var filterName = Fixture.String();
                var filterValue = Fixture.String();

                var s1 = new StepDelta(name, type, filterName, filterValue);
                var s2 = new StepDelta(name, type, filterName, filterValue);

                s1.ScreenTip = Fixture.String();
                s1.Title = Fixture.String();
                s1.IsMandatory = false;

                s2.ScreenTip = Fixture.String();
                s2.Title = Fixture.String();
                s2.IsMandatory = true;

                Assert.True(_subject.Equals(s1, s2), "Should match on name and the provided filter");
                Assert.True(_subject.Equals(s1, s1));
                Assert.True(_subject.Equals(s2, s2));

                Assert.False(ReferenceEquals(s1, s2));
                Assert.False(ReferenceEquals(s1.Categories.Single(), s2.Categories.Single()));
            }

            [Fact]
            public void ReturnFalseWhenFilterNameDontMatch()
            {
                var name = Fixture.String();
                var filterValue = Fixture.String();

                var s1 = new StepDelta(name, "b", "checklist", filterValue);
                var s2 = new StepDelta(name, "b", "numberType", filterValue);

                Assert.False(_subject.Equals(s1, s2));
            }

            [Fact]
            public void ReturnFalseWhenFilterValueDontMatch()
            {
                var name = Fixture.String();
                var filterName = Fixture.String();

                var s1 = new StepDelta(name, "c", filterName, Fixture.String());
                var s2 = new StepDelta(name, "c", filterName, Fixture.String());

                Assert.False(_subject.Equals(s1, s2));
            }

            [Fact]
            public void ReturnFalseWhenNameDontMatch()
            {
                var s1 = new StepDelta(Fixture.String(), "a");
                var s2 = new StepDelta(Fixture.String(), "a");

                Assert.False(_subject.Equals(s1, s2));
            }
        }

        public class TopicControlAndStepDeltaComparison
        {
            readonly FlattenTopicEqualityComparer _subject = new FlattenTopicEqualityComparer();

            [Theory]
            [InlineData("checklist", "ChecklistTypeKey")]
            [InlineData("numberType", "NumberTypeKeys")]
            [InlineData("textType", "TextTypeKey")]
            [InlineData("action", "CreateActionKey")]
            [InlineData("designationStage", "CountryFlag")]
            [InlineData("nameType", "NameTypeKey")]
            public void MatchNameWithSingleFilter(string type, string filterName)
            {
                var name = Fixture.String();
                var filterValue = Fixture.String();

                var topicControl = TopicControlBuilder.For(name, new TopicControlFilter(filterName, filterValue)).Build();
                var stepDelta = new StepDelta(name, Fixture.String(), type, filterValue);

                topicControl.ScreenTip = Fixture.String();
                topicControl.Title = Fixture.String();
                topicControl.IsMandatory = false;

                stepDelta.ScreenTip = Fixture.String();
                stepDelta.Title = Fixture.String();
                stepDelta.IsMandatory = true;

                Assert.True(_subject.Equals(topicControl, stepDelta), $"Should match on name and the provided filter {filterName}");
                Assert.True(_subject.Equals(topicControl, topicControl));
                Assert.True(_subject.Equals(stepDelta, stepDelta));
            }

            [Theory]
            [InlineData("checklist", "ChecklistTypeKey")]
            [InlineData("numberType", "NumberTypeKey")]
            [InlineData("textType", "TextTypeKey")]
            [InlineData("action", "CreateActionKey")]
            [InlineData("countryFlag", "CountryFlag")]
            [InlineData("nameType", "NameTypeKey")]
            public void ReturnFalseWhenFilterValueDontMatch(string type, string filterName)
            {
                var name = Fixture.String();

                var topicControl = TopicControlBuilder.For(Fixture.String(), new TopicControlFilter(filterName, Fixture.String())).Build();
                var stepDelta = new StepDelta(name, Fixture.String(), type, Fixture.String());

                Assert.False(_subject.Equals(topicControl, stepDelta));
            }

            [Fact]
            public void MatchByNameOnly()
            {
                var name = Fixture.String();
                var type = Fixture.String();

                var topicControl = TopicControlBuilder.For(name).Build();
                var stepDelta = new StepDelta(name, type);

                topicControl.Title = Fixture.String();
                topicControl.ScreenTip = Fixture.String();
                topicControl.RowPosition = Fixture.Short();
                topicControl.IsInherited = false;
                topicControl.IsMandatory = true;

                stepDelta.ScreenTip = Fixture.String();
                stepDelta.Title = Fixture.String();
                stepDelta.IsMandatory = true;

                Assert.True(_subject.Equals(topicControl, stepDelta), "Should only match on name when filters are both null");
                Assert.True(_subject.Equals(topicControl, topicControl));
                Assert.True(_subject.Equals(stepDelta, stepDelta));
            }

            [Fact]
            public void MatchNameWithBothFilters()
            {
                var name = Fixture.String();
                var filterValue1 = Fixture.String();
                var filterValue2 = Fixture.String();

                var topicControl = TopicControlBuilder.For(name, new TopicControlFilter("NameTypeKey", filterValue1), new TopicControlFilter("TextTypeKey", filterValue2)).Build();
                var stepDelta = new StepDelta(name, "X", "nameType", filterValue1, "textType", filterValue2);

                topicControl.ScreenTip = Fixture.String();
                topicControl.Title = Fixture.String();
                topicControl.IsMandatory = false;

                stepDelta.ScreenTip = Fixture.String();
                stepDelta.Title = Fixture.String();
                stepDelta.IsMandatory = true;

                Assert.True(_subject.Equals(topicControl, stepDelta), "Should match on name and both filters");
                Assert.True(_subject.Equals(topicControl, topicControl));
                Assert.True(_subject.Equals(stepDelta, stepDelta));
            }

            [Fact]
            public void ReturnFalseWhenFilterNameDontMatch()
            {
                var name = Fixture.String();
                var filterValue = Fixture.String();

                var topicControl = TopicControlBuilder.For(Fixture.String(), new TopicControlFilter(Fixture.String(), filterValue)).Build();
                var stepDelta = new StepDelta(name, "b", "numberType", filterValue);

                Assert.False(_subject.Equals(topicControl, stepDelta));
            }

            [Fact]
            public void ReturnFalseWhenNameDontMatch()
            {
                var topicControl = TopicControlBuilder.For(Fixture.String()).Build();
                var stepDelta = new StepDelta(Fixture.String(), "G");

                Assert.False(_subject.Equals(topicControl, stepDelta));
            }
        }
    }
}