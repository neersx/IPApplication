using System;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case.CaseSearch;
using Inprotech.Web.Search.Name;
using InprotechKaizen.Model.Components.Names.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Queries;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Name
{
    public class NameSearchServiceFacts : FactBase
    {
        [Fact]
        public void ShouldUpdateXmlCriteriaForSavedSearch()
        {
            var f = new NameSearchServiceFixture(Db);
            var id = SetupFilterCriteriaData(Db);

            var searchParams = new SearchExportParams<NameSearchRequestFilter<NameSearchRequest>>
            {
                QueryKey = id,
                DeselectedIds = new[] { 1, 2, 3 },
                Criteria = new NameSearchRequestFilter<NameSearchRequest>()
            };

            f.Subject.UpdateFilterForBulkOperation(searchParams);
            var xmlCriteria = XElement.Parse(searchParams.Criteria.XmlSearchRequest);
            Assert.NotNull(xmlCriteria);
            Assert.Equal(2, xmlCriteria.DescendantsAndSelf("FilterCriteria").Count());

            var addedStep = xmlCriteria.DescendantsAndSelf("FilterCriteria").Last().ToString();
            const string filterCriteria = "<FilterCriteria ID=\"2\" BooleanOperator=\"AND\">\r\n  <IsCeased>0</IsCeased>\r\n  <IsLead>0</IsLead>\r\n  <IsCurrent>1</IsCurrent>\r\n  <NameKeys Operator=\"1\">\r\n    <NameKey>1</NameKey>\r\n    <NameKey>2</NameKey>\r\n    <NameKey>3</NameKey>\r\n  </NameKeys>\r\n</FilterCriteria>";
            Assert.Equal(addedStep,filterCriteria );
        }

        [Fact]
        public void ShouldUpdateXmlCriteriaForSavedSearchAndDeselectedIds()
        {
            var f = new NameSearchServiceFixture(Db);
            var deselectedIds = new[] {1, 2, 3};
            var queryId = SetupFilterCriteriaData(Db);
            var searchParams = new SearchExportParams<NameSearchRequestFilter<NameSearchRequest>>
            {
                QueryKey = queryId,
                DeselectedIds = deselectedIds,
                Criteria = new NameSearchRequestFilter<NameSearchRequest>()
            };

            f.Subject.UpdateFilterForBulkOperation(searchParams);

            AssertUpdatedXmlForDeselectedIdFilter(searchParams.Criteria.XmlSearchRequest, deselectedIds);
        }

        [Fact]
        public void ShouldUpdateXmlCriteriaForXmlSearchAndDeselectedIds()
        {
            var f = new NameSearchServiceFixture(Db);
            var deselectedIds = new[] {1, 2, 3};
            var searchParams = new SearchExportParams<NameSearchRequestFilter<NameSearchRequest>>
            {
                DeselectedIds = deselectedIds,
                Criteria = new NameSearchRequestFilter<NameSearchRequest>
                {
                    XmlSearchRequest = PrepareFilterCriteria()
                }
            };

            f.Subject.UpdateFilterForBulkOperation(searchParams);
            AssertUpdatedXmlForDeselectedIdFilter(searchParams.Criteria.XmlSearchRequest, deselectedIds);
        }

        [Fact]
        public void ShouldReturnXmlFilterCriteriaAsItIs()
        {
            var f = new NameSearchServiceFixture(Db);

            var filterCriteria = @"<Search>
	                <Filtering>
		                <naw_ListName>
			                <FilterCriteriaGroup>
				                <FilterCriteria>
					                <AnySearch></AnySearch>
                                    <NameKeys Operator='0'></NameKeys>
                                    <IsCurrent>1</IsCurrent>
                                    <IsCeased>0</IsCeased>
                                    <IsLead>0</IsLead>
				                </FilterCriteria>
			                </FilterCriteriaGroup>
		                </naw_ListName>
	                </Filtering>
                </Search>";

            var searchParams = new SearchExportParams<NameSearchRequestFilter<NameSearchRequest>>
            {
                QueryKey = 1,
                Criteria = new NameSearchRequestFilter<NameSearchRequest>
                {
                    SearchRequest = new[]
                    {
                        new NameSearchRequest()
                    },
                    XmlSearchRequest = filterCriteria
                }
            };

            f.Subject.UpdateFilterForBulkOperation(searchParams);

            Assert.Equal(filterCriteria, searchParams.Criteria.XmlSearchRequest);
        }
       
        int SetupFilterCriteriaData(InMemoryDbContext db)
        {
            var queryFiler = db.Set<QueryFilter>().Add(new QueryFilter {ProcedureName = "naw_ListName", XmlFilterCriteria = PrepareFilterCriteria()}).In(db);
            var query = db.Set<Query>().Add(new Query {Name = "Search 1", ContextId = 2, IdentityId = null, FilterId = queryFiler.Id}).In(db);

            return query.Id;
        }

        string PrepareFilterCriteria()
        {
            var filterCriteria = @"<Search>
	                <Filtering>
		                <csw_ListCase>
			                <FilterCriteriaGroup>
				                <FilterCriteria>
					                <AnySearch></AnySearch>
                                    <NameKeys Operator='0'></NameKeys>
                                    <IsCurrent>1</IsCurrent>
                                    <IsCeased>0</IsCeased>
                                    <IsLead>0</IsLead>
				                </FilterCriteria>
			                </FilterCriteriaGroup>
		                </csw_ListCase>
	                </Filtering>
                </Search>";
            return filterCriteria;
        }

        void AssertUpdatedXmlForDeselectedIdFilter(string updatedXmlCriteria, int[] deselectedIds)
        {
            var xmlCriteria = XElement.Parse(updatedXmlCriteria);

            Assert.NotNull(xmlCriteria);
            Assert.Equal(2, xmlCriteria.DescendantsAndSelf("FilterCriteria").Count());
            var addedStep = xmlCriteria.DescendantsAndSelf("FilterCriteria").Last();
            Assert.Equal("2", addedStep.GetAttributeStringValue("ID"));
            Assert.Equal("0", addedStep.DescendantsAndSelf("IsCeased").First().Value);
            Assert.Equal((short) CollectionExtensions.FilterOperator.NotIn, addedStep.DescendantsAndSelf("NameKeys").First().GetAttributeIntValue("Operator"));
            var xmlDeselectedIds = addedStep.Descendants("NameKey").Select(x => Convert.ToInt32(x.Value)).ToArray();
            Assert.Equal(deselectedIds.Length, deselectedIds.Intersect(xmlDeselectedIds).Count());
        }
    }

    public class NameSearchServiceFixture : IFixture<INameSearchService>
    {
        public NameSearchServiceFixture(InMemoryDbContext db)
        {
            XmlFilterCriteriaBuilderResolver = Substitute.For<IXmlFilterCriteriaBuilderResolver>();
            FilterableColumnsMapResolver = Substitute.For<IFilterableColumnsMapResolver>();

            Subject = new NameSearchService(db, XmlFilterCriteriaBuilderResolver, FilterableColumnsMapResolver);
        }

        public INameSearchService Subject { get; }

        public IXmlFilterCriteriaBuilderResolver XmlFilterCriteriaBuilderResolver { get; set; }
        public IFilterableColumnsMapResolver FilterableColumnsMapResolver { get; set; }
    }
}