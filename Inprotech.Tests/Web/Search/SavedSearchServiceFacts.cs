using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Names.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class SavedSearchServiceFacts
    {
        public class SaveSearchMethod : FactBase
        {
            const string SearchName = "New Search";

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldUpdatePresentationForColumnFilterData(bool isPublic)
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.CaseSearch);

                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = true, SortOrder = 1, SortDirection = "A"},
                    new SelectedColumn {ColumnKey = 2, DisplaySequence = 2}
                };

                var savedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = SearchName,
                    XmlFilter = "<csw_ListCase/>",
                    Description = "New Search Description",
                    GroupKey = 1,
                    IsPublic = isPublic,
                    SelectedColumns = selectedColumns
                };

                var r = f.Subject.SaveSearch(savedSearch);

                var query = Db.Set<Query>().First();
                var queryFilter = Db.Set<QueryFilter>().First(_ => _.Id == query.FilterId);
                var queryPresentation = Db.Set<QueryPresentation>().First(_ => _.Id == query.PresentationId);
                var queryColumns = Db.Set<QueryContent>().Where(_ => _.PresentationId == query.PresentationId).OrderBy(_ => _.ColumnId).ToList();

                Assert.True(r.Success);
                Assert.Equal(r.QueryKey, query.Id);

                Assert.Equal(query.IdentityId, isPublic ? (int?) null : f.User.Id);
                Assert.Equal(query.ContextId, 2);
                Assert.Equal(query.GroupId, 1);
                Assert.Equal(query.Name, SearchName);
                Assert.Equal(query.Description, "New Search Description");

                Assert.Equal(queryFilter.XmlFilterCriteria, "<csw_ListCase/>");

                Assert.Equal(queryPresentation.ContextId, 2);
                Assert.Equal(queryPresentation.FreezeColumnId, 1);
                Assert.Equal(queryPresentation.IdentityId, isPublic ? (int?) null : f.User.Id);
                Assert.False(queryPresentation.IsDefault);

                Assert.Equal(queryColumns.Count, selectedColumns.Count);
                Assert.Equal(queryColumns[0].ColumnId, 1);
                Assert.Equal(queryColumns[0].ContextId, 2);
                Assert.Equal(queryColumns[0].SortOrder, (short) 1);
                Assert.Equal(queryColumns[0].SortDirection, "A");
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldReturnFailureIfNameAlreadyExists(bool isPublic)
            {
                var f = new SavedSearchServiceFixture(Db);

                Db.Set<Query>().Add(new Query {Name = SearchName, ContextId = 2, IdentityId = isPublic ? (int?) null : f.User.Id}).In(Db);

                var savedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = SearchName,
                    IsPublic = isPublic
                };

                var r = f.Subject.SaveSearch(savedSearch);

                Assert.False(r.Success);
                Assert.Equal(r.Error, "duplicate");
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldReturnSuccessIfNameAlreadyExistsButIsNotPublic(bool isPublic)
            {
                var f = new SavedSearchServiceFixture(Db);

                var user = new User("internal", false).In(Db);
                f.SecurityContext.User.Returns(user);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.CaseSearch);

                new Query {Name = SearchName, ContextId = 2, IdentityId = isPublic ? user.Id : (int?) null}.In(Db);

                var savedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = SearchName,
                    IsPublic = isPublic
                };

                var r = f.Subject.SaveSearch(savedSearch);

                Assert.True(r.Success);
            }

            [Fact]
            public void ShouldNotAddPresentationDataForDefaultSearch()
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.CaseSearch);

                var savedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = SearchName
                };

                var r = f.Subject.SaveSearch(savedSearch);

                var query = Db.Set<Query>().First();
                var queryPresentation = Db.Set<QueryPresentation>().ToList();
                var queryColumns = Db.Set<QueryContent>().ToList();

                Assert.True(r.Success);
                Assert.Equal(r.QueryKey, query.Id);

                Assert.Equal(query.ContextId, 2);
                Assert.Equal(query.Name, SearchName);

                Assert.Null(query.PresentationId);
                Assert.Equal(queryPresentation.Count, 0);
                Assert.Equal(queryColumns.Count, 0);
            }

            [Fact]
            public void ShouldThrowExceptionIfSearchNameIsEmpty()
            {
                var f = new SavedSearchServiceFixture(Db);

                Assert.Throws<ArgumentException>(() => { f.Subject.SaveSearch<CaseSearchRequestFilter>(null); });

                Assert.Throws<ArgumentException>(() => { f.Subject.SaveSearch(new FilteredSavedSearch<CaseSearchRequestFilter>()); });
            }
        }

        public class UpdateSavedSearchMethod : FactBase
        {
            const string SearchName = "New Search";

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldReturnFailureIfNameAlreadyExists(bool isPublic)
            {
                var f = new SavedSearchServiceFixture(Db);

                var updatedCaseSearch = Db.Set<Query>().Add(new Query {Name = SearchName, ContextId = 2, IdentityId = isPublic ? (int?) null : f.User.Id}).In(Db);
                Db.Set<Query>().Add(new Query {Name = "Case Search 2", ContextId = 2, IdentityId = isPublic ? (int?) null : f.User.Id}).In(Db);

                var savedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = "Case Search 2",
                    IsPublic = isPublic
                };

                var r = f.Subject.Update(updatedCaseSearch.Id, savedSearch, true);

                Assert.False(r.Success);
                Assert.Equal(r.Error, "duplicate");
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldReturnSuccessIfNameAlreadyExistsButIsNotPublic(bool isPublic)
            {
                var f = new SavedSearchServiceFixture(Db);

                var user = new User("internal", false).In(Db);
                f.SecurityContext.User.Returns(user);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.CaseSearch);

                new Query
                {
                    Name = SearchName,
                    ContextId = 2,
                    IdentityId = isPublic ? (int?) null : f.User.Id,
                    FilterId = new QueryFilter().In(Db).Id
                }.In(Db);

                var updatedCaseSearch = new Query
                {
                    Name = "Case Search 2",
                    ContextId = 2,
                    IdentityId = null,
                    FilterId = new QueryFilter().In(Db).Id
                }.In(Db);

                var savedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = SearchName
                };

                var r = f.Subject.Update(updatedCaseSearch.Id, savedSearch, true);

                Assert.True(r.Success);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldNotUpdateDetailsIfUpdateDetailsIsSetToFalse(bool isPublic)
            {
                var f = new SavedSearchServiceFixture(Db);

                var user = new User("internal", false).In(Db);
                f.SecurityContext.User.Returns(user);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.CaseSearch);

                var caseSearch = new Query
                {
                    Name = SearchName,
                    ContextId = 2,
                    IdentityId = isPublic ? (int?) null : f.User.Id,
                    FilterId = new QueryFilter().In(Db).Id
                }.In(Db);

                var savedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = "Case Search Updated"
                };

                var r = f.Subject.Update(caseSearch.Id, savedSearch);

                var result = Db.Set<Query>().First(cs => cs.Id == caseSearch.Id);

                Assert.True(r.Success);
                Assert.Equal(result.Name, caseSearch.Name);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldUpdateDetailsIfUpdateDetailsSetToTrue(bool isPublic)
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.CaseSearch);

                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = true, SortOrder = 1, SortDirection = "A"},
                    new SelectedColumn {ColumnKey = 2, DisplaySequence = 2}
                };

                var user = new User("internal", false).In(Db);
                f.SecurityContext.User.Returns(user);

                var savedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = SearchName,
                    XmlFilter = "<csw_ListCase/>",
                    Description = "Search Description",
                    GroupKey = 1,
                    IsPublic = true,
                    SelectedColumns = selectedColumns
                };

                f.Subject.SaveSearch(savedSearch);

                var newSelectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = false, SortOrder = 1, SortDirection = "D"},
                    new SelectedColumn {ColumnKey = 2, DisplaySequence = 2},
                    new SelectedColumn {ColumnKey = 3, DisplaySequence = 3}
                };

                var updatedSavedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = "Case Search Updated",
                    XmlFilter = "<csw_ListCase><FilterCriteriaGroup><FilterCriteria ID=\'1\'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter><StandingInstructions IncludeInherited=\'0\' /><StatusFlags CheckDeadCaseRestriction=\'1\' /><CountryCodes Operator=\'0\'>GB</CountryCodes><InheritedName /><CaseNameGroup /><AttributeGroup BooleanOr=\'0\' /><Event Operator=\'\' IsRenewalsOnly=\'0\' IsNonRenewalsOnly=\'0\' ByEventDate=\'1\'><Period><Type></Type><Quantity></Quantity></Period></Event><Actions /></FilterCriteria></FilterCriteriaGroup><ColumnFilterCriteria><DueDates UseEventDates=\'1\' UseAdHocDates=\'0\'><Dates UseDueDate=\'0\' UseReminderDate=\'0\' /><Actions IncludeClosed=\'0\' IsRenewalsOnly=\'1\' IsNonRenewalsOnly=\'1\' /><DueDateResponsibilityOf IsAnyName=\'0\' IsStaff=\'0\' IsSignatory=\'0\' /></DueDates></ColumnFilterCriteria></csw_ListCase>",
                    Description = "New Search Description",
                    GroupKey = 1,
                    IsPublic = true,
                    SelectedColumns = newSelectedColumns,
                    UpdatePresentation = true
                };

                var query = Db.Set<Query>().First();

                var r = f.Subject.Update(query.Id, updatedSavedSearch, true);

                var queryFilter = Db.Set<QueryFilter>().First(_ => _.Id == query.FilterId);
                var queryPresentation = Db.Set<QueryPresentation>().First(_ => _.Id == query.PresentationId);
                var queryColumns = Db.Set<QueryContent>().Where(_ => _.PresentationId == query.PresentationId).OrderBy(_ => _.ColumnId).ToList();

                Assert.True(r.Success);

                Assert.Equal(query.IdentityId, null);
                Assert.Equal(query.GroupId, 1);
                Assert.Equal(query.Name, "Case Search Updated");
                Assert.Equal(query.Description, "New Search Description");

                Assert.Equal(queryFilter.XmlFilterCriteria, "<csw_ListCase><FilterCriteriaGroup><FilterCriteria ID=\'1\'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter><StandingInstructions IncludeInherited=\'0\' /><StatusFlags CheckDeadCaseRestriction=\'1\' /><CountryCodes Operator=\'0\'>GB</CountryCodes><InheritedName /><CaseNameGroup /><AttributeGroup BooleanOr=\'0\' /><Event Operator=\'\' IsRenewalsOnly=\'0\' IsNonRenewalsOnly=\'0\' ByEventDate=\'1\'><Period><Type></Type><Quantity></Quantity></Period></Event><Actions /></FilterCriteria></FilterCriteriaGroup><ColumnFilterCriteria><DueDates UseEventDates=\'1\' UseAdHocDates=\'0\'><Dates UseDueDate=\'0\' UseReminderDate=\'0\' /><Actions IncludeClosed=\'0\' IsRenewalsOnly=\'1\' IsNonRenewalsOnly=\'1\' /><DueDateResponsibilityOf IsAnyName=\'0\' IsStaff=\'0\' IsSignatory=\'0\' /></DueDates></ColumnFilterCriteria></csw_ListCase>");

                Assert.Equal(queryPresentation.ContextId, 2);
                Assert.Equal(queryPresentation.FreezeColumnId, null);
                Assert.False(queryPresentation.IsDefault);

                Assert.Equal(queryColumns.Count, newSelectedColumns.Count);
                Assert.Equal(queryColumns[0].ColumnId, 1);
                Assert.Equal(queryColumns[0].ContextId, 2);
                Assert.Equal(queryColumns[0].SortOrder, (short) 1);
                Assert.Equal(queryColumns[0].SortDirection, "D");
            }
        }

        public class RevertAndDefaultMethod : FactBase
        {
            const string SearchName = "Case Search";

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldMakeDefaultPresentation(bool isPublic)
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.NameSearch);

                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = true, SortOrder = 1, SortDirection = "A"},
                    new SelectedColumn {ColumnKey = 2, DisplaySequence = 2}
                };

                var savedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchName = SearchName,
                    XmlFilter = "<csw_ListCase/>",
                    Description = "Search Description",
                    GroupKey = 1,
                    IsPublic = isPublic,
                    SelectedColumns = selectedColumns
                };

                f.Subject.SaveSearch(savedSearch);

                var queryPresentation = Db.Set<QueryPresentation>().FirstOrDefault(_ => _.IsDefault);

                Assert.Null(queryPresentation);

                var r = f.Subject.MakeMyDefaultPresentation(savedSearch);
                queryPresentation = Db.Set<QueryPresentation>().First(_ => _.IsDefault);
                var queryContent = Db.Set<QueryContent>().Where(_ => _.PresentationId == queryPresentation.Id);
                Assert.True(r);
                Assert.NotNull(queryPresentation);
                Assert.Equal(queryContent.Count(), 2);
            }

            [Fact]
            public void ShouldRevertToDefaultPresentation()
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.NameSearch);

                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = true, SortOrder = 1, SortDirection = "A"},
                    new SelectedColumn {ColumnKey = 2, DisplaySequence = 2}
                };

                var savedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchName = SearchName,
                    XmlFilter = "<csw_ListCase/>",
                    Description = "Search Description",
                    GroupKey = 1,
                    IsPublic = false,
                    SelectedColumns = selectedColumns
                };

                f.Subject.SaveSearch(savedSearch);
                f.Subject.MakeMyDefaultPresentation(savedSearch);

                var queryPresentation = Db.Set<QueryPresentation>().First(_ => _.IsDefault);
                var presentation = queryPresentation;
                var queryContent = Db.Set<QueryContent>().Where(_ => _.PresentationId == presentation.Id);

                Assert.NotNull(queryPresentation);
                Assert.Equal(queryContent.Count(), 2);

                f.Subject.RevertToDefault(savedSearch.QueryContext);

                var revertQueryPresentation = Db.Set<QueryPresentation>().FirstOrDefault(_ => _.IsDefault);
                queryContent = Db.Set<QueryContent>().Where(_ => _.ContextId == queryPresentation.Id);

                Assert.Null(revertQueryPresentation);
                Assert.Equal(queryContent.Count(), 0);
            }
        }

        public class DeleteSavedSearch : FactBase
        {
            [Fact]
            public void DeletesSavedSearch()
            {
                var f = new SavedSearchServiceFixture(Db);

                var user = new User("internal", false).In(Db);
                f.SecurityContext.User.Returns(user);

                var queryFilter = Db.Set<QueryFilter>().Add(new QueryFilter {ProcedureName = "csw_ListCase", XmlFilterCriteria = "<Search></Search>"}).In(Db);
                var queryPresentation = Db.Set<QueryPresentation>().Add(new QueryPresentation {ContextId = 2, IdentityId = user.Id, IsDefault = false}).In(Db);
                var query = Db.Set<Query>().Add(new Query {Name = "New Search", ContextId = 2, IdentityId = user.Id, FilterId = queryFilter.Id, PresentationId = queryPresentation.Id}).In(Db);

                var r = f.Subject.DeleteSavedSearch(query.Id);

                Assert.True(r);
                Assert.Empty(Db.Set<Query>());
                Assert.Empty(Db.Set<QueryFilter>());
                Assert.Empty(Db.Set<QueryPresentation>());
            }

            [Fact]
            public void ThrowsExceptionWhenSavedQueryNotFound()
            {
                var f = new SavedSearchServiceFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.DeleteSavedSearch(Fixture.Integer()));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ShouldNotDeleteDefaultSavedSearchForTaskPlanner()
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.TaskPlanner);
                var user = new User("internal", false).In(Db);
                f.SecurityContext.User.Returns(user);
                var queryPresentation = Db.Set<QueryPresentation>().Add(new QueryPresentation { ContextId = 970, IdentityId = user.Id, IsDefault = false }).In(Db);
                
                var query = Db.Set<Query>().Add(new Query {Id = -31, Name = "My Reminders", ContextId = 970, IdentityId = user.Id, FilterId = -31, PresentationId = queryPresentation.Id }).In(Db);
                var myReminder = f.Subject.DeleteSavedSearch(query.Id);

                Assert.False(myReminder);

                var queryMyDueDate = Db.Set<Query>().Add(new Query {Id = -29, Name = "My Due Dates", ContextId = 970, IdentityId = user.Id, FilterId = -29, PresentationId = queryPresentation.Id }).In(Db);
                var myDueDate = f.Subject.DeleteSavedSearch(queryMyDueDate.Id);

                Assert.False(myDueDate);
               
                var queryMyTeamTask = Db.Set<Query>().Add(new Query {Id = -28, Name = "My Team's Tasks", ContextId = 970, IdentityId = user.Id, FilterId = -28, PresentationId = queryPresentation.Id }).In(Db);
                var myTeamTask = f.Subject.DeleteSavedSearch(queryMyTeamTask.Id);

                Assert.False(myTeamTask);
            }

            [Fact]
            public void DeletesSavedSearchForTaskPlanner()
            {
                var f = new SavedSearchServiceFixture(Db);

                var user = new User("internal", false).In(Db);
                f.SecurityContext.User.Returns(user);

                var queryFilter = Db.Set<QueryFilter>().Add(new QueryFilter {ProcedureName = "ipw_TaskPlanner", XmlFilterCriteria = "<Search></Search>"}).In(Db);
                var queryPresentation = Db.Set<QueryPresentation>().Add(new QueryPresentation { ContextId = 970, IdentityId = user.Id, IsDefault = false }).In(Db);
                var query = Db.Set<Query>().Add(new Query {Name = "New Saved Search", ContextId = 970, IdentityId = user.Id, FilterId = queryFilter.Id, PresentationId = queryPresentation.Id }).In(Db);

                var r = f.Subject.DeleteSavedSearch(query.Id);

                Assert.True(r);
                Assert.Empty(Db.Set<Query>());
                Assert.Empty(Db.Set<QueryFilter>());
                Assert.Empty(Db.Set<QueryPresentation>());
            }

        }

        public class SaveAsSearchMethod : FactBase
        {
            [Fact]
            public void ShouldCopyPresentationAndQueryColumnFromExistingSavedSearch()
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.NameSearch);

                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = true, SortOrder = 1, SortDirection = "A"},
                    new SelectedColumn {ColumnKey = 2, DisplaySequence = 2},
                    new SelectedColumn {ColumnKey = 3, DisplaySequence = 3, SortOrder = 2, SortDirection = "A"}
                };

                var saveSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchName = "Search 1",
                    XmlFilter = "<csw_ListCase/>",
                    Description = "New Search Description",
                    GroupKey = 1,
                    IsPublic = true,
                    SelectedColumns = selectedColumns
                };

                var saveResult = f.Subject.SaveSearch(saveSearch);
                var fromQueryKey = (int) saveResult.QueryKey;

                saveSearch.SearchName = saveSearch.SearchName + " Copy";
                saveSearch.Description = "search copy description";
                saveSearch.XmlFilter = "<csw_ListCase><CaseKey>-487<CaseKey></csw_ListCase>";
                saveSearch.SelectedColumns = selectedColumns;
                saveSearch.UpdatePresentation = false;

                var r = f.Subject.SaveAsSearch(fromQueryKey, saveSearch);
                var newSavedQueryKey = (int) r.QueryKey;

                var newSavedQuery = Db.Set<Query>().Single(_ => _.Id == newSavedQueryKey);
                var queryFilter = Db.Set<QueryFilter>().Single(_ => _.Id == newSavedQuery.FilterId);
                var queryPresentation = Db.Set<QueryPresentation>().Single(_ => _.Id == newSavedQuery.PresentationId);
                var queryColumns = Db.Set<QueryContent>().Where(_ => _.PresentationId == newSavedQuery.PresentationId).OrderBy(_ => _.ColumnId).ToList();

                Assert.True(r.Success);
                Assert.NotNull(newSavedQuery);
                Assert.Equal(saveSearch.SearchName, newSavedQuery.Name);
                Assert.NotNull(queryFilter);
                Assert.Equal("<csw_ListCase><CaseKey>-487<CaseKey></csw_ListCase>", queryFilter.XmlFilterCriteria);
                Assert.NotNull(queryPresentation);
                Assert.NotEmpty(queryColumns);
                Assert.Equal(3, queryColumns.Count);
            }

            [Fact]
            public void ShouldEnsureFilterCriteriaFromExistingSavedSearch()
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.NameSearch);

                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = true, SortOrder = 1, SortDirection = "A"},
                    new SelectedColumn {ColumnKey = 2, DisplaySequence = 2},
                    new SelectedColumn {ColumnKey = 3, DisplaySequence = 3, SortOrder = 2, SortDirection = "A"}
                };

                var originalSavedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchName = "Search 1",
                    XmlFilter = "<csw_ListCase/>",
                    Description = "New Search Description",
                    GroupKey = 1,
                    IsPublic = true,
                    SelectedColumns = selectedColumns
                };

                var copiedSavedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchName = originalSavedSearch.SearchName + " Copy",
                    Description = "search copy description",
                    XmlFilter = null,
                    GroupKey = 1,
                    IsPublic = true,
                    SelectedColumns = selectedColumns.Except(new[] {selectedColumns.First()}),
                    UpdatePresentation = true
                };

                var saveResult = f.Subject.SaveSearch(originalSavedSearch);
                var fromQueryKey = (int) saveResult.QueryKey;

                var r = f.Subject.SaveAsSearch(fromQueryKey, copiedSavedSearch);
                var newSavedQueryKey = (int) r.QueryKey;

                var newSavedQuery = Db.Set<Query>().Single(_ => _.Id == newSavedQueryKey);
                var queryFilter = Db.Set<QueryFilter>().Single(_ => _.Id == newSavedQuery.FilterId);
                var queryPresentation = Db.Set<QueryPresentation>().Single(_ => _.Id == newSavedQuery.PresentationId);
                var queryColumns = Db.Set<QueryContent>().Where(_ => _.PresentationId == newSavedQuery.PresentationId).OrderBy(_ => _.ColumnId).ToList();

                Assert.True(r.Success);
                Assert.NotNull(newSavedQuery);
                Assert.Equal(copiedSavedSearch.SearchName, newSavedQuery.Name);
                Assert.NotNull(queryFilter);
                Assert.Equal("<csw_ListCase/>", queryFilter.XmlFilterCriteria);
                Assert.NotNull(queryPresentation);
                Assert.NotEmpty(queryColumns);
                Assert.Equal(2, queryColumns.Count);
            }

            [Fact]
            public void ShouldSaveAsFromExistingSearch()
            {
                var f = new SavedSearchServiceFixture(Db);

                new QueryContextModel().In(Db).WithKnownId((int) QueryContext.CaseSearch);

                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1, IsFreezeColumnIndex = true, SortOrder = 1, SortDirection = "A"},
                    new SelectedColumn {ColumnKey = 2, DisplaySequence = 2},
                    new SelectedColumn {ColumnKey = 3, DisplaySequence = 3, SortOrder = 2, SortDirection = "A"}
                };

                var saveSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchName = "Search 1",
                    XmlFilter = "<csw_ListCase/>",
                    Description = "New Search Description",
                    GroupKey = 1,
                    IsPublic = true,
                    SelectedColumns = selectedColumns
                };

                var saveResult = f.Subject.SaveSearch(saveSearch);
                var fromQueryKey = saveResult.QueryKey;

                saveSearch.SearchName = saveSearch.SearchName + " Copy";
                saveSearch.Description = "search copy description";
                saveSearch.XmlFilter = "<csw_ListCase><CaseKey>-487<CaseKey></csw_ListCase>";
                selectedColumns.Add(new SelectedColumn {ColumnKey = 4, DisplaySequence = 4, SortOrder = 3, SortDirection = "D"});
                saveSearch.SelectedColumns = selectedColumns;
                saveSearch.UpdatePresentation = true;

                var r = f.Subject.SaveAsSearch(fromQueryKey, saveSearch);
                var newSavedQueryKey = (int) r.QueryKey;

                var newSavedQuery = Db.Set<Query>().Single(_ => _.Id == newSavedQueryKey);
                var queryFilter = Db.Set<QueryFilter>().Single(_ => _.Id == newSavedQuery.FilterId);
                var queryPresentation = Db.Set<QueryPresentation>().Single(_ => _.Id == newSavedQuery.PresentationId);
                var queryColumns = Db.Set<QueryContent>().Where(_ => _.PresentationId == newSavedQuery.PresentationId).OrderBy(_ => _.ColumnId).ToList();

                Assert.True(r.Success);
                Assert.NotNull(newSavedQuery);
                Assert.Equal(saveSearch.SearchName, newSavedQuery.Name);
                Assert.NotNull(queryFilter);
                Assert.Equal("<csw_ListCase><CaseKey>-487<CaseKey></csw_ListCase>", queryFilter.XmlFilterCriteria);
                Assert.NotNull(queryPresentation);
                Assert.NotEmpty(queryColumns);
                Assert.Equal(4, queryColumns.Count);
            }
        }

        public class SavedSearchServiceFixture : IFixture<SavedSearchService>
        {
            public SavedSearchServiceFixture(InMemoryDbContext db)
            {
                DbContext = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                XmlFilterCriteriaBuilder = Substitute.For<IXmlFilterCriteriaBuilder>();
                XmlFilterCriteriaBuilderResolver = Substitute.For<IXmlFilterCriteriaBuilderResolver>();
                XmlFilterCriteriaBuilderResolver.Resolve(Arg.Any<QueryContext>())
                                                       .Returns(XmlFilterCriteriaBuilder);

                User = new User("internal", false).In(db);
                SecurityContext.User.Returns(User);
                PreferredCultureResolver.Resolve().Returns("US");

                Subject = new SavedSearchService(DbContext, SecurityContext, PreferredCultureResolver, XmlFilterCriteriaBuilderResolver);
            }

            public ISecurityContext SecurityContext { get; }
            public IDbContext DbContext { get; }
            public IXmlFilterCriteriaBuilder XmlFilterCriteriaBuilder { get; }
            public IXmlFilterCriteriaBuilderResolver XmlFilterCriteriaBuilderResolver { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public User User { get; }
            public SavedSearchService Subject { get; set; }
        }
    }
}