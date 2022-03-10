using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Configuration.Checklists.Search
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ChecklistConfigurationExactMatchSearch : ChecklistConfigurationSearchBase
    {
        [Test]
        public void ShouldReturnOnlyNonProtectedRules()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 11, "should return only 1 user-defined criteria");
        }

        [Test]
        public void ShouldReturnAllCriteriaMatchingTheChecklistType()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = true
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 12, "should return both protected and user-defined criteria");
        }

        [Test]
        public void ShouldReturnOnlyMatchingOffice()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Office = Data.Office
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria with matching office");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Office = Data.UnusedOffice
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria not matching office");
        }

        [Test]
        public void ShouldReturnOnlyMatchingCaseType()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseType = Data.CaseType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria with matching case type");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseType = Data.UnusedCaseType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria not matching case type");
        }

        [Test]
        public void ShouldReturnOnlyMatchingJurisdiction()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Jurisdiction = Data.Jurisdiction
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria with matching jurisdiction");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Jurisdiction = Data.UnusedJurisdiction
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria not matching jurisdiction");
        }

        [Test]
        public void ShouldReturnOnlyMatchingPropertyType()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                PropertyType = Data.PropertyType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria with matching property type");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                PropertyType = Data.UnusedPropertyType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria not matching the property type");
        }

        [Test]
        public void ShouldReturnOnlyMatchingCaseCategory()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseCategory = Data.CaseCategory
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria with matching case category");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseCategory = Data.UnusedCaseCategory
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria not matching the case category");
        }

        [Test]
        public void ShouldReturnOnlyMatchingSubType()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                SubType = Data.SubType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria with matching subtype");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                SubType = Data.UnusedSubType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria not matching the sub type");
        }

        [Test]
        public void ShouldReturnOnlyMatchingBasis()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Basis = Data.Basis
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria with matching basis");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                Basis = Data.UnusedBasis
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria not matching the basis");
        }

        [Test]
        public void ShouldReturnRulesForLocalClientsOnly()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                ApplyTo = ClientFilterOptions.LocalClients
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all criteria for local clients");

            searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                ApplyTo = ClientFilterOptions.ForeignClients
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 0, "should not return criteria not applying to local clients");
        }

        [Test]
        public void ReturnsAllRulesWithChecklistFiltered()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.AnotherChecklist.Id
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all rules when checklist matches exactly");
        }

        [Test]
        public void ReturnsAllRulesWithChecklistAndCountryFiltered()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                CaseType = Data.CaseType
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 2, "should return all rules when checklist and case type matches exactly");
        }

        [Test]
        public void ShouldReturnCriteriaMatchingAllOrPartOfFilterCharacteristics()
        {
            var searchCriteria = new SearchCriteria
            {
                MatchType = CriteriaMatchOptions.ExactMatch,
                Checklist = Data.Checklist.Id,
                IncludeProtectedCriteria = false,
                CaseType = Data.CaseType,
                Jurisdiction = Data.Jurisdiction,
                PropertyType = Data.PropertyType,
                CaseCategory = Data.CaseCategory,
                SubType = Data.SubType,
                Basis = Data.Basis,
                ApplyTo = ClientFilterOptions.LocalClients,
                Office = Data.Office,
            };

            ChecklistSearchTestHelper.AssertCriteriaReturnsCount(User, searchCriteria, 1, "should only return criteria exactly matching filter characteristics");
        }
    }
}