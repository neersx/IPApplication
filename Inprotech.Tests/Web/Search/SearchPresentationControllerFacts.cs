using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.Columns;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class SearchPresentationControllerFacts : FactBase
    {
        [Fact]
        public void ExecutesCaseSearchAvailableColumnsPassingParams()
        {
            var f = new SearchPresentationControllerFixture(Db);
            var availableColumns = new List<PresentationColumn> { new PresentationColumn { ColumnKey = 1, GroupKey = 2 } };
            var availableColumnGroup = new List<ColumnGroup> { new ColumnGroup { GroupKey = 2 } };
            var queryContextKey = QueryContext.CaseSearch;

            f.PresentationColumnsResolver.AvailableColumns(queryContextKey).ReturnsForAnyArgs(availableColumns);
            f.PresentationColumnsResolver.AvailableColumnGroups(queryContextKey).ReturnsForAnyArgs(availableColumnGroup);

            var r = f.Subject.AvailableColumns(queryContextKey).ToList();

            Assert.Equal(2, r.Count);
            Assert.True(r[0].IsGroup);
            Assert.Equal(r[0].Id, "2_G");
            Assert.Null(r[0].ParentId);

            Assert.False(r[1].IsGroup);
            Assert.Equal(r[1].Id, "1_C");
            Assert.Equal(r[1].ParentId, "2_G");

            f.PresentationColumnsResolver.Received(1).AvailableColumns(queryContextKey);
            f.PresentationColumnsResolver.Received(1).AvailableColumnGroups(queryContextKey);
        }

        [Fact]
        public void ExecutesCaseSearchSelectedColumnsPassingParams()
        {
            var f = new SearchPresentationControllerFixture(Db);
            var presentationColumns = new List<PresentationColumn>
            {
                new PresentationColumn {ColumnKey = 1, IsFreezeColumnIndex = true, DisplaySequence = 1},
                new PresentationColumn {ColumnKey = 2, IsFreezeColumnIndex = false, DisplaySequence = 2, GroupKey = 1},
                new PresentationColumn {ColumnKey = 3, IsFreezeColumnIndex = false}
            };
            var queryContextKey = QueryContext.CaseSearch;

            f.PresentationColumnsResolver.Resolve(null, null).ReturnsForAnyArgs(presentationColumns);

            var r = f.Subject.SelectedColumns(queryContextKey, null).ToList();

            Assert.Equal(r.Count, 3);

            Assert.Equal(r[0].Id, "1_C");
            Assert.True(r[0].FreezeColumn);
            Assert.Null(r[0].ParentId);
            Assert.False(r[0].Hidden);

            Assert.Equal(r[1].Id, "2_C");
            Assert.False(r[1].FreezeColumn);
            Assert.Equal(r[1].ParentId, "1_G");
            Assert.False(r[1].Hidden);

            Assert.Equal(r[2].Id, "3_C");
            Assert.False(r[2].FreezeColumn);
            Assert.Null(r[2].ParentId);
            Assert.True(r[2].Hidden);

            f.PresentationColumnsResolver.Received(1).Resolve(null, queryContextKey);
        }

        [Fact]
        public void ViewData()
        {
            var queryContextKey = QueryContext.CaseSearch;
            var permissions = new SearchMaintenability(queryContextKey,
                                                       canMaintainPublicSearch: Fixture.Boolean(),
                                                       canUpdateSavedSearch: Fixture.Boolean(),
                                                       canDeleteSavedSearch: Fixture.Boolean(),
                                                       canCreateSavedSearch: Fixture.Boolean());
            var columnPermissions = new SearchColumnMaintainability(queryContextKey,
                                                       canCreateSearchColumn: true,
                                                       canUpdateSearchColumn: true,
                                                       canDeleteSearchColumn: true);
            var f = new SearchPresentationControllerFixture(Db);
            f.SearchMaintainabilityResolver.Resolve(queryContextKey)
             .Returns(permissions);
            f.SearchColumnMaintainabilityResolver.Resolve(queryContextKey).Returns(columnPermissions);

            var presentationColumns = new List<PresentationColumn>
            {
                new PresentationColumn {ColumnKey = 1, IsFreezeColumnIndex = true, DisplaySequence = 1},
                new PresentationColumn {ColumnKey = 2, IsFreezeColumnIndex = false, DisplaySequence = 2, GroupKey = 1},
                new PresentationColumn {ColumnKey = 3, IsFreezeColumnIndex = false}
            };

            new QueryPresentation
            {
                AccessAccountId = null,
                ContextId = (int)queryContextKey,
                IsDefault = true,
                IdentityId =
                    f.SecurityContext.User.Id
            }.In(Db);

            f.PresentationColumnsResolver.Resolve(null, null).ReturnsForAnyArgs(presentationColumns);

            var r = f.Subject.ViewData(queryContextKey);

            Assert.Equal(permissions.CanMaintainPublicSearch, r.CanMaintainPublicSearch);
            Assert.Equal(permissions.CanCreateSavedSearch, r.CanCreateSavedSearch);
            Assert.Equal(permissions.CanUpdateSavedSearch, r.CanUpdateSavedSearch);
            Assert.Equal(permissions.CanDeleteSavedSearch, r.CanDeleteSavedSearch);
            Assert.True(r.canMaintainColumns);

            f.SavedQueries.Received(1).GetSavedPresentationQueries((int)queryContextKey);
        }

        [Fact]
        public void ExecutesMakeMyDefaultPresentation()
        {
            var f = new SearchPresentationControllerFixture(Db);

            var savedSearch = new Inprotech.Web.Search.SavedSearch
            {
                QueryContext = QueryContext.CaseSearch,
                IsPublic = true
            };

            var permissions = new SearchMaintenability(QueryContext.CaseSearch,
                                                       canMaintainPublicSearch: Fixture.Boolean(),
                                                       canUpdateSavedSearch: true,
                                                       canDeleteSavedSearch: Fixture.Boolean(),
                                                       canCreateSavedSearch: Fixture.Boolean());

            f.SearchMaintainabilityResolver.Resolve(QueryContext.CaseSearch)
             .Returns(permissions);

            f.Subject.MakeMyDefaultPresentation(savedSearch);
            f.SavedSearchService.Received(1).MakeMyDefaultPresentation(Arg.Any<Inprotech.Web.Search.SavedSearch>());
        }

        [Theory]
        [InlineData(QueryContext.CaseSearch)]
        [InlineData(QueryContext.NameSearch)]
        [InlineData(QueryContext.CampaignSearch)]
        [InlineData(QueryContext.MarketingEventSearch)]
        [InlineData(QueryContext.OpportunitySearch)]
        [InlineData(QueryContext.PriorArtSearch)]
        [InlineData(QueryContext.LeadSearch)]
        public void ThrowsExceptionWhenTaskNotGrantedMakeMyDefaultPresentation(QueryContext queryContext)
        {
            var f = new SearchPresentationControllerFixture(Db);

            var savedSearch = new Inprotech.Web.Search.SavedSearch
            {
                QueryContext = queryContext,
                IsPublic = true
            };

            var permissions = new SearchMaintenability(queryContext,
                                                       canMaintainPublicSearch: Fixture.Boolean(),
                                                       canUpdateSavedSearch: false,
                                                       canDeleteSavedSearch: Fixture.Boolean(),
                                                       canCreateSavedSearch: Fixture.Boolean());

            f.SearchMaintainabilityResolver.Resolve(queryContext)
             .Returns(permissions);

            Assert.Throws<UnauthorizedAccessException>(() => f.Subject.MakeMyDefaultPresentation(savedSearch));
        }

        [Fact]
        public void ExecutesRevertToDefault()
        {
            var f = new SearchPresentationControllerFixture(Db);
            var permissions = new SearchMaintenability(QueryContext.CaseSearch,
                                                       canMaintainPublicSearch: Fixture.Boolean(),
                                                       canUpdateSavedSearch: true,
                                                       canDeleteSavedSearch: Fixture.Boolean(),
                                                       canCreateSavedSearch: Fixture.Boolean());

            f.SearchMaintainabilityResolver.Resolve(QueryContext.CaseSearch)
             .Returns(permissions);

            const QueryContext queryContextKey = QueryContext.CaseSearch;
            f.Subject.RevertToDefault(queryContextKey);
            f.SavedSearchService.Received(1).RevertToDefault(queryContextKey);
        }

        [Theory]
        [InlineData(QueryContext.CaseSearch)]
        [InlineData(QueryContext.NameSearch)]
        [InlineData(QueryContext.CampaignSearch)]
        [InlineData(QueryContext.MarketingEventSearch)]
        [InlineData(QueryContext.OpportunitySearch)]
        [InlineData(QueryContext.PriorArtSearch)]
        [InlineData(QueryContext.LeadSearch)]
        public void ThrowsExceptionWhenTaskNotGrantedRevertToDefault(QueryContext queryContext)
        {
            var f = new SearchPresentationControllerFixture(Db);

            var permissions = new SearchMaintenability(queryContext,
                                                       canMaintainPublicSearch: Fixture.Boolean(),
                                                       canUpdateSavedSearch: false,
                                                       canDeleteSavedSearch: Fixture.Boolean(),
                                                       canCreateSavedSearch: Fixture.Boolean());

            f.SearchMaintainabilityResolver.Resolve(queryContext)
             .Returns(permissions);

            Assert.Throws<UnauthorizedAccessException>(() => f.Subject.RevertToDefault(queryContext));
        }

        [Fact]
        public void ThrowsArgumentNullExceptionWhenSavedSearchIsNull()
        {
            var f = new SearchPresentationControllerFixture(Db);
            Assert.Throws<ArgumentNullException>(() => { f.Subject.MakeMyDefaultPresentation(null); });
        }
    }

    public class SearchPresentationControllerFixture : IFixture<SearchPresentationController>
    {
        public SearchPresentationControllerFixture(InMemoryDbContext db)
        {
            PresentationColumnsResolver = Substitute.For<IPresentationColumnsResolver>();
            SavedQueries = Substitute.For<ISavedQueries>();
            SecurityContext = Substitute.For<ISecurityContext>();
            CaseSearchService = Substitute.For<ICaseSearchService>();
            SecurityContext.User.Returns(new User(Fixture.String(), false));
            DbContext = db;
            SearchMaintainabilityResolver = Substitute.For<ISearchMaintainabilityResolver>();
            SavedSearchService = Substitute.For<ISavedSearchService>();
            SearchColumnMaintainabilityResolver = Substitute.For<ISearchColumnMaintainabilityResolver>();

            Subject = new SearchPresentationController(PresentationColumnsResolver, SavedQueries, SecurityContext, CaseSearchService, SearchMaintainabilityResolver, DbContext, SavedSearchService, SearchColumnMaintainabilityResolver);
        }

        public IPresentationColumnsResolver PresentationColumnsResolver { get; set; }
        public ISavedQueries SavedQueries { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public ICaseSearchService CaseSearchService { get; set; }
        public ISearchMaintainabilityResolver SearchMaintainabilityResolver { get; set; }
        public IDbContext DbContext { get; set; }
        public SearchPresentationController Subject { get; }
        public ISavedSearchService SavedSearchService { get; set; }
        public ISearchColumnMaintainabilityResolver SearchColumnMaintainabilityResolver { get; set; }
    }
}