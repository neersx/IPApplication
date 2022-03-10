using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class SearchPresentationServiceFacts : FactBase
    {
        const string Category = "Presentation";

        static readonly SearchPresentation Presentation = new SearchPresentation
        {
            ColumnFormats = new List<ColumnFormat>
            {
                new ColumnFormat
                {
                    Id = "CountryName",
                    Title = "col1",
                    Filterable = false
                },
                new ColumnFormat
                {
                    Id = "CaseTypeDescription",
                    Title = "col2",
                    Filterable = false
                },
                new ColumnFormat
                {
                    Id = "PropertyTypeDescription",
                    Title = "col3",
                    Filterable = false
                }
            },

            OutputRequests = new List<OutputRequest>
            {
                new OutputRequest {PublishName = "CountryName"},
                new OutputRequest {PublishName = "CountryCode"},
                new OutputRequest {PublishName = "CaseTypeDescription"},
                new OutputRequest {PublishName = "PropertyTypeDescription"}
            }
        };

        [Trait("Category", Category)]
        public class Facts
        {
            [Fact]
            public void ShouldUpdatePresentationForColumnFilterData()
            {
                var presentationManager = new SearchPresentationServiceFixture();
                var presentation = Presentation;

                presentationManager.Subject.UpdatePresentationForColumnFilterData(presentation, "CountryName", "CountryCode");

                Assert.Contains(presentation.OutputRequests, o => o.PublishName.Equals("CountryName"));
                Assert.DoesNotContain(presentation.OutputRequests, o => !o.PublishName.Equals("CountryName") && !o.PublishName.Equals("CountryCode"));
            }

            [Fact]
            public void ShouldUpdatePresentationForColumnSort()
            {
                var presentationManager = new SearchPresentationServiceFixture();
                var presentation = Presentation;
                presentationManager.Subject.UpdatePresentationForColumnSort(presentation, "CountryName", "asc");

                Assert.Equal(1, presentation.OutputRequests.Single(o => o.PublishName.Equals("CountryName")).SortOrder);
                Assert.Equal(SortDirectionType.Ascending, presentation.OutputRequests.Single(o => o.PublishName.Equals("CountryName")).SortDirection);
            }
        }

        public class SearchPresentationServiceFixture : IFixture<SearchPresentationService>
        {
            public SearchPresentationServiceFixture()
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                
                DbContext = Substitute.For<IDbContext>();
                
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                PreferredCultureResolver.Resolve().Returns("En");
                
                var filterableColumnsMap = Substitute.For<IFilterableColumnsMap>();
                filterableColumnsMap.Columns.Returns(new Dictionary<string, string>());

                FilterableColumnsMapResolver = Substitute.For<IFilterableColumnsMapResolver>();
                FilterableColumnsMapResolver.Resolve(Arg.Any<QueryContext>()).Returns(filterableColumnsMap);
                
                Subject = new SearchPresentationService(SecurityContext, DbContext, PreferredCultureResolver, FilterableColumnsMapResolver);
            }

            //QuickSearchResult _searchResult = new QuickSearchResult();
            public ISecurityContext SecurityContext { get; }
            public IDbContext DbContext { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public IFilterableColumnsMapResolver FilterableColumnsMapResolver { get; set; }
            public SearchPresentationService Subject { get; set; }
        }
    }
}