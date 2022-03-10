using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case
{
    public class SavedSearchMaintenanceControllerFacts
    {
        static CaseSearchRequestFilter PrepareCaseSearchFilter()
        {
            return new CaseSearchRequestFilter
            {
                DueDateFilter = new DueDateFilter
                {
                    DueDates = new DueDates
                    {
                        UseAdHocDates = 1,
                        UseEventDates = 1,
                        Dates = new InprotechKaizen.Model.Components.Cases.Search.Dates
                        {
                            UseDueDate = 1,
                            UseReminderDate = 0,
                            PeriodRange = new PeriodRange
                            {
                                From = 1,
                                Operator = "7",
                                To = 20,
                                Type = "M"
                            }
                        }
                    }
                },
                SearchRequest = new[]
                {
                    new CaseSearchRequest
                    {
                        CaseReference = new SearchElement {Value = "abc", Operator = 1},
                        OfficialNumber = new OfficialNumberElement
                        {
                            Number = new OfficialNumberNumber {UseNumericSearch = 1, Value = "987"},
                            Operator = 2,
                            TypeKey = "A",
                            UseRelatedCase = 1,
                            UseCurrent = 0
                        }
                    }
                }
            };
        }

        static string PrepareFilterCriteria()
        {
            const string filterCriteria = @"<Search><Report><ReportTitle>AU</ReportTitle></Report><Filtering><csw_ListCase>
                                <FilterCriteriaGroup>
                                    <FilterCriteria ID='1'>
                                        <AccessMode>1</AccessMode>
                                        <IsAdvancedFilter>false</IsAdvancedFilter>
                                        <CountryCodes Operator='0'>AU</CountryCodes><InheritedName /><CaseNameGroup />
                                    </FilterCriteria>
                                    <FilterCriteria BooleanOperator='OR' ID='2'>
                                        <AccessMode>1</AccessMode>
                                        <IsAdvancedFilter>false</IsAdvancedFilter>
                                        <CaseReference Operator='2'>1234</CaseReference><InheritedName /><CaseNameGroup />
                                    </FilterCriteria>
                                    <FilterCriteria BooleanOperator='OR' ID='3'>
                                        <AccessMode>1</AccessMode>
                                        <IsAdvancedFilter>false</IsAdvancedFilter>
                                        <PropertyTypeKeys Operator='0'><PropertyTypeKey>T</PropertyTypeKey></PropertyTypeKeys>
                                    </FilterCriteria>
                                </FilterCriteriaGroup></csw_ListCase></Filtering></Search>";
            return filterCriteria;
        }

        public class AddMethod : FactBase
        {
            [Fact]
            public void ExecutesCaseSavedSearchPassingParams()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);
                var req = new CaseSearchRequestFilter
                {
                    SearchRequest = new[]
                    {
                        new CaseSearchRequest {CaseReference = new SearchElement {Value = "abc", Operator = 1}}
                    }
                };
                var caseSavedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveSearch<CaseSearchRequestFilter>(null).ReturnsForAnyArgs(new { Success = true });

                f.Subject.Add(caseSavedSearch);

                f.SavedSearchService.Received(1).SaveSearch(Arg.Any<FilteredSavedSearch<CaseSearchRequestFilter>>());
            }

            [Fact]
            public void ThrowsExceptionIfFilterIsNull()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);

                var caseSavedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>();

                Assert.Throws<ArgumentNullException>(() => { f.Subject.Add(caseSavedSearch); });
            }

            [Fact]
            public void ThrowsExceptionIfItIsPublicSearchAndDoesNotHaveAccessToTask()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);

                var caseSavedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    IsPublic = true,
                    SearchFilter = new CaseSearchRequestFilter()
                };

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);

                Assert.Throws<UnauthorizedAccessException>(() => { f.Subject.Add(caseSavedSearch); });
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void Get()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);
                var queryKey = 2;
                f.Subject.Get(queryKey);
                f.SavedSearchService.Received(1).Get(queryKey);
            }

            [Fact]
            public void ThrowsExceptionIfQueryKeyIsNull()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Get(null); });
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ThrowsUnauthorizedAccessExceptionIfNotPublic()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);
                var caseSavedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);
                var queryKey = 2;

                Assert.Throws<UnauthorizedAccessException>(() => { f.Subject.UpdateDetails(queryKey, caseSavedSearch); });
            }

            [Fact]
            public void Update()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);

                var caseSavedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);

                var filterCriteria = PrepareFilterCriteria();

                var req = PrepareCaseSearchFilter();

                caseSavedSearch.SearchFilter = req;
                var queryFiler = Db.Set<QueryFilter>().Add(new QueryFilter { ProcedureName = "csw_ListCase", XmlFilterCriteria = filterCriteria }).In(Db);
                var query = Db.Set<Query>().Add(new Query { Name = "Search 1", ContextId = 2, IdentityId = null, FilterId = queryFiler.Id }).In(Db);

                f.Subject.Update(query.Id, caseSavedSearch);
                f.SavedSearchService.Received(1).Update(query.Id, Arg.Any<FilteredSavedSearch<CaseSearchRequestFilter>>());
            }

            [Fact]
            public void UpdateWhenSearchRequestIsNull()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);

                var caseSavedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    IsPublic = true
                };

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);

                var filterCriteria = PrepareFilterCriteria();

                var req = PrepareCaseSearchFilter();
                req.SearchRequest = null;
                caseSavedSearch.SearchFilter = req;
                var queryFiler = Db.Set<QueryFilter>().Add(new QueryFilter { ProcedureName = "csw_ListCase", XmlFilterCriteria = filterCriteria }).In(Db);
                var query = Db.Set<Query>().Add(new Query { Name = "Search 1", ContextId = 2, IdentityId = null, FilterId = queryFiler.Id }).In(Db);

                f.Subject.Update(query.Id, caseSavedSearch);
                f.SavedSearchService.Received(1).Update(query.Id, Arg.Any<FilteredSavedSearch<CaseSearchRequestFilter>>());
            }

            [Fact]
            public void UpdateDetails()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);

                var caseSavedSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);

                var filterCriteria = PrepareFilterCriteria();

                var req = PrepareCaseSearchFilter();

                caseSavedSearch.SearchFilter = req;
                var queryFiler = Db.Set<QueryFilter>().Add(new QueryFilter { ProcedureName = "csw_ListCase", XmlFilterCriteria = filterCriteria }).In(Db);
                var query = Db.Set<Query>().Add(new Query { Name = "Search 1", ContextId = 2, IdentityId = null, FilterId = queryFiler.Id }).In(Db);
                f.Subject.Update(query.Id, caseSavedSearch);
                f.SavedSearchService.Received(1).Update(query.Id, Arg.Any<FilteredSavedSearch<CaseSearchRequestFilter>>());
            }
        }

        public class SaveAsMethod : FactBase
        {
            [Fact]
            public void ExecutesSaveAs()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);
                var req = PrepareCaseSearchFilter();
                var caseSaveAsSearch = new FilteredSavedSearch<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    SearchFilter = req
                };

                var filterCriteria = PrepareFilterCriteria();

                var queryFiler = Db.Set<QueryFilter>().Add(new QueryFilter { ProcedureName = "csw_ListCase", XmlFilterCriteria = filterCriteria }).In(Db);
                var query = Db.Set<Query>().Add(new Query { Name = "Search 1", ContextId = 2, IdentityId = null, FilterId = queryFiler.Id }).In(Db);

                f.SavedSearchService.SaveAsSearch<CaseSearchRequestFilter>(query.Id, null).ReturnsForAnyArgs(new { Success = true });
                f.Subject.SaveAs(query.Id, caseSaveAsSearch);

                f.SavedSearchService.Received(1).SaveAsSearch(query.Id, Arg.Any<FilteredSavedSearch<CaseSearchRequestFilter>>());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSavedSearchIsNull()
            {
                var f = new CaseSearchMaintenanceControllerFixture(Db);
                Assert.Throws<ArgumentNullException>(() => { f.Subject.SaveAs(Fixture.Integer(), null); });
            }
        }
    }

    public class CaseSearchMaintenanceControllerFixture : IFixture<SavedSearchMaintenanceController>
    {
        public CaseSearchMaintenanceControllerFixture(InMemoryDbContext db)
        {
            SavedSearchService = Substitute.For<ISavedSearchService>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User());

            Subject = new SavedSearchMaintenanceController(securityContext, SavedSearchService, TaskSecurityProvider, db);
        }

        public ISavedSearchService SavedSearchService { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public SavedSearchMaintenanceController Subject { get; }
    }
}