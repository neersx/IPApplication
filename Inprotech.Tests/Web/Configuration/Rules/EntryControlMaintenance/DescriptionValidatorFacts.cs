using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance
{
    public class DescriptionValidatorFacts
    {
        public class ValidateChangeFunction : FactBase
        {
            public ValidateChangeFunction()
            {
                _subject = new DescriptionValidator(Db);
            }

            readonly IDescriptionValidator _subject;

            [Theory]
            [InlineData("")]
            [InlineData(null)]
            public void ReturnsErrorIfDescriptionIsNullOrEmpty(string descriptionToUpdate)
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.Build().In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = descriptionToUpdate};

                criteria.DataEntryTasks = new List<DataEntryTask>
                {
                    entryToUpdate,
                    otherEntry
                };
                var result = _subject.Validate(criteria.Id, entryToUpdate.Description, updatedValues.Description);

                Assert.NotNull(result);
                Assert.Equal("definition", result.Topic);
                Assert.Equal("description", result.Field);
                Assert.Equal("field.errors.required", result.Message);
            }

            [Fact]
            public void ReturnsErrorIfUpdatedDescriptionIsNotUnique()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.Build().In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = "An old Entry"};

                criteria.DataEntryTasks = new List<DataEntryTask>
                {
                    entryToUpdate,
                    otherEntry
                };
                var result = _subject.Validate(criteria.Id, entryToUpdate.Description, updatedValues.Description);

                Assert.NotNull(result);
                Assert.Equal("definition", result.Topic);
                Assert.Equal("description", result.Field);
                Assert.Equal("field.errors.notunique", result.Message);
            }

            [Fact]
            public void ReturnsWithoutErrorsIfDescriptionUnModified()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.Build().In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = "A new Entry"};

                criteria.DataEntryTasks = new List<DataEntryTask>
                {
                    entryToUpdate,
                    otherEntry
                };

                var result = _subject.Validate(criteria.Id, entryToUpdate.Description, updatedValues.Description);

                Assert.Null(result);
            }
        }

        public class IsDescriptionUniqueFunction : FactBase
        {
            readonly IDescriptionValidator _subject;

            public IsDescriptionUniqueFunction()
            {
                _subject = new DescriptionValidator(Db);
            }

            [Theory]
            [InlineData("abcd", "abcd&@#@$#$%", true)]
            [InlineData("     ijkm         ", "ijkm", true)]
            [InlineData("efgh&4", "abcd*()", false)]
            public void CheckIfDescriptionIsUniqueForNormalEntries(string currentDesc, string newDesc, bool expectedResult)
            {
                var criteria = new CriteriaBuilder {Description = "Criteria"}.Build().In(Db);
                short entryId = 1;

                var existingEntries = new[] {"abcd", "efgh&4", "     ijkm         "};
                foreach (var desc in existingEntries) criteria.DataEntryTasks.Add(new DataEntryTask(criteria, entryId++) {Description = desc}.In(Db));

                var result = _subject.IsDescriptionUnique(criteria.Id, currentDesc, newDesc);

                Assert.Equal(expectedResult, result);
            }

            [Theory]
            [InlineData("desc", "----", false)]
            [InlineData("desc", "new desc()", false)]
            [InlineData("desc", "new desc", true)]
            public void CheckIfDescriptionIsUniqueForNormalEntriesWithExactMatchInSeparator(string currentDesc, string newDesc, bool expectedResult)
            {
                var criteria = new CriteriaBuilder {Description = "Criteria"}.Build().In(Db);
                short entryId = 1;

                var existingEntries = new[] {"----", "####", "            ", "new desc()"};
                foreach (var desc in existingEntries) criteria.DataEntryTasks.Add(new DataEntryTask(criteria, entryId++) {Description = desc, IsSeparator = true}.In(Db));

                criteria.DataEntryTasks.Add(new DataEntryTask(criteria, entryId) {Description = "desc", IsSeparator = true});

                var result = _subject.IsDescriptionUnique(criteria.Id, currentDesc, newDesc);

                Assert.Equal(expectedResult, result);
            }

            [Theory]
            [InlineData("----", "----", true)]
            [InlineData("            ", "  A  ", true)]
            [InlineData("####", "----", false)]
            public void CheckIfDescriptionIsUniqueForSeparatorEntries(string currentDesc, string newDesc, bool expectedResult)
            {
                var criteria = new CriteriaBuilder {Description = "Criteria"}.Build().In(Db);
                short entryId = 1;

                var existingEntries = new[] {"----", "####", "            "};
                foreach (var desc in existingEntries) criteria.DataEntryTasks.Add(new DataEntryTask(criteria, entryId++) {Description = desc, IsSeparator = true}.In(Db));

                var result = _subject.IsDescriptionUnique(criteria.Id, currentDesc, newDesc, true);

                Assert.Equal(expectedResult, result);
            }
        }

        public class IsDescriptionUniqueInFunction : FactBase
        {
            readonly IDescriptionValidator _subject;

            public IsDescriptionUniqueInFunction()
            {
                _subject = new DescriptionValidator(Db);
            }

            [Theory]
            [InlineData("abcd&@#@$#$%", false)]
            [InlineData("ijkm", false)]
            [InlineData("abcd*()1", true)]
            public void CheckIfDescriptionIsUniqueForNormalEntries(string newDesc, bool expectedResult)
            {
                var criteria = new CriteriaBuilder {Description = "Criteria"}.Build().In(Db);
                short entryId = 1;

                var existingEntries = new[] {"abcd", "efgh&4", "     ijkm         "};
                foreach (var desc in existingEntries) criteria.DataEntryTasks.Add(new DataEntryTask(criteria, entryId++) {Description = desc}.In(Db));

                var result = _subject.IsDescriptionUniqueIn(criteria.DataEntryTasks.ToArray(), newDesc);

                Assert.Equal(expectedResult, result);
            }

            [Theory]
            [InlineData("----", false)]
            [InlineData("new desc()", false)]
            [InlineData("new desc", true)]
            public void CheckIfDescriptionIsUniqueForNormalEntriesWithExactMatchInSeparator(string newDesc, bool expectedResult)
            {
                var criteria = new CriteriaBuilder {Description = "Criteria"}.Build().In(Db);
                short entryId = 1;

                var existingEntries = new[] {"----", "####", "            ", "new desc()"};
                foreach (var desc in existingEntries) criteria.DataEntryTasks.Add(new DataEntryTask(criteria, entryId++) {Description = desc, IsSeparator = true}.In(Db));

                criteria.DataEntryTasks.Add(new DataEntryTask(criteria, entryId) {Description = "desc", IsSeparator = true});

                var result = _subject.IsDescriptionUniqueIn(criteria.DataEntryTasks.ToArray(), newDesc);

                Assert.Equal(expectedResult, result);
            }

            [Theory]
            [InlineData("-------", true)]
            [InlineData("  A  ", true)]
            [InlineData(" ", true)]
            [InlineData("----", false)]
            public void CheckIfDescriptionIsUniqueForSeparatorEntries(string newDesc, bool expectedResult)
            {
                var criteria = new CriteriaBuilder {Description = "Criteria"}.Build().In(Db);
                short entryId = 1;

                var existingEntries = new[] {"----", "####", "            "};
                foreach (var desc in existingEntries) criteria.DataEntryTasks.Add(new DataEntryTask(criteria, entryId++) {Description = desc, IsSeparator = true}.In(Db));

                var result = _subject.IsDescriptionUniqueIn(criteria.DataEntryTasks.ToArray(), newDesc, true);

                Assert.Equal(expectedResult, result);
            }
        }

        public class IsDescriptionExisting : FactBase
        {
            readonly DescriptionValidator _subject;

            public IsDescriptionExisting()
            {
                _subject = new DescriptionValidator(Db);
            }

            void AddEntries(Criteria criteria, string[] entryDescs, bool separators = false)
            {
                var entryId = criteria.DataEntryTasks.Any() ? criteria.DataEntryTasks.Max(_ => _.Id) : 1;
                foreach (var desc in entryDescs) criteria.DataEntryTasks.Add(new DataEntryTask(criteria, (short) entryId++) {Description = desc, IsSeparator = separators}.In(Db));
            }

            [Theory]
            [InlineData("a_a", new[] {0, 1})]
            [InlineData("BBB", new[] {0, 1, 2, 3})]
            [InlineData("C ", new[] {0, 2, 3})]
            public void ReturnsCriteriaIdsWhereDescriptionIsExisting(string newDesc, int[] expectedCriteria)
            {
                var criterias = new[]
                {
                    new CriteriaBuilder {Description = "Criteria1"}.Build().In(Db),
                    new CriteriaBuilder {Description = "Criteria2"}.Build().In(Db),
                    new CriteriaBuilder {Description = "Criteria3"}.Build().In(Db),
                    new CriteriaBuilder {Description = "Criteria4"}.Build().In(Db)
                };

                AddEntries(criterias[0], new[] {"A----A", "BB##B", "C"});
                AddEntries(criterias[1], new[] {"A()a", "B#B##B", "CC"});
                AddEntries(criterias[2], new[] {"A", "B##B#B", " C  __"});
                AddEntries(criterias[2], new[] {"A__A"}, true);
                AddEntries(criterias[3], new[] {"aab", "B##BB__   ", "A C"});
                AddEntries(criterias[3], new[] {"c "}, true);

                var result = _subject.IsDescriptionExisting(criterias.Select(_ => _.Id).ToArray(), newDesc).ToArray();

                Assert.Equal(expectedCriteria.Length, result.Length);

                foreach (var expected in expectedCriteria) Assert.Contains(criterias[expected].Id, result);
            }

            [Theory]
            [InlineData("a_a", new[] {0, 2})]
            [InlineData("BBB", new[] {3})]
            [InlineData("C ", new[] {3})]
            public void ReturnsCriteriaIdsWhereDescriptionIsExistingForSeparators(string newDesc, int[] expectedCriteria)
            {
                var criterias = new[]
                {
                    new CriteriaBuilder {Description = "Criteria1"}.Build().In(Db),
                    new CriteriaBuilder {Description = "Criteria2"}.Build().In(Db),
                    new CriteriaBuilder {Description = "Criteria3"}.Build().In(Db),
                    new CriteriaBuilder {Description = "Criteria4"}.Build().In(Db)
                };

                AddEntries(criterias[0], new[] {"A_A", "BB##B", "C"});
                AddEntries(criterias[1], new[] {"A()a", "B#B##B", "CC"});
                AddEntries(criterias[2], new[] {"A", "B##B#B", "-C "});
                AddEntries(criterias[2], new[] {"A_A"}, true);
                AddEntries(criterias[3], new[] {"aab", "BBB", "C "});
                AddEntries(criterias[3], new[] {"A  A"}, true);

                var result = _subject.IsDescriptionExisting(criterias.Select(_ => _.Id).ToArray(), newDesc, true).ToArray();

                Assert.Equal(expectedCriteria.Length, result.Length);

                foreach (var expected in expectedCriteria) Assert.Contains(criterias[expected].Id, result);
            }
        }
    }
}