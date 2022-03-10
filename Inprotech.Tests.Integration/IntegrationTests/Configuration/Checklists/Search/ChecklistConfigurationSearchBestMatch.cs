using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Configuration.Checklists.Search
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ChecklistConfigurationSearchBestMatch : ChecklistConfigurationSearchBase
    {
        [Test]
        public void ShouldNotReturnIfNoChecklistOrCaseTypeSpecified()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria if no checklist type or case type provided");
        }

        [Test]
        public void ShouldReturnOnlyNonProtectedRulesWhereSpecified()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should return only 1 user-defined criteria");
        }

        [Test]
        public void ShouldReturnOnlyCorrectPurposeCodeRecordsAndInUse()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = true
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return 2 non-user-defined criteria");
        }

        [Test]
        public void ShouldReturnOnlyMatchingOffice()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Office = Data.Office
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria including those with matching office");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Office = Data.UnusedOffice
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should not return criteria not matching office");
        }

        [Test]
        public void ShouldReturnOnlyMatchingCaseType()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseType = Data.CaseType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria including those with matching case type");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseType = Data.UnusedCaseType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should not return criteria not matching case type");
        }

        [Test]
        public void ShouldReturnOnlyMatchingJurisdiction()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Jurisdiction = Data.Jurisdiction
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria including those with matching jurisdiction");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Jurisdiction = Data.UnusedJurisdiction
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should not return criteria not matching jurisdiction");
        }

        [Test]
        public void ShouldReturnOnlyMatchingPropertyType()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                PropertyType = Data.PropertyType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria including those with matching property type");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                PropertyType = Data.UnusedPropertyType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should not return criteria not matching the property type");
        }

        [Test]
        public void ShouldReturnOnlyMatchingCaseCategory()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseCategory = Data.CaseCategory
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria including those with matching case category");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseCategory = Data.UnusedCaseCategory
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should not return criteria not matching the case category");
        }

        [Test]
        public void ShouldReturnOnlyMatchingSubType()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                SubType = Data.SubType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria including those with matching subtype");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                SubType = Data.UnusedSubType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should not return criteria not matching the sub type");
        }

        [Test]
        public void ShouldReturnOnlyMatchingBasis()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Basis = Data.Basis
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria including those with matching basis");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Basis = Data.UnusedBasis
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should not return criteria not matching the basis");
        }

        [Test]
        public void ShouldReturnRulesForLocalClientsOnly()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                ApplyTo = ClientFilterOptions.LocalClients
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria including those for local clients");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                ApplyTo = ClientFilterOptions.ForeignClients
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should not return criteria not applying to local clients");
        }

        [Test]
        public void ShouldReturnCriteriaMatchingAllOrPartOfFilterCharacteristics()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.BestMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseType = Data.CaseType,
                Jurisdiction = Data.Jurisdiction,
                PropertyType = Data.PropertyType,
                CaseCategory = Data.CaseCategory,
                SubType = Data.SubType,
                Basis = Data.Basis,
                ApplyTo = ClientFilterOptions.LocalClients
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 8, "should return all criteria matching all or part of the filter characteristics");
        }
    }
}