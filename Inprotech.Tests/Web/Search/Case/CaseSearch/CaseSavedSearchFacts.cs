using Inprotech.Web.Search.Case.CaseSearch;
using Inprotech.Web.Search.Case.CaseSearch.DueDate;
using NSubstitute;
using System.Collections.Generic;
using System.Web;
using System.Xml.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class CaseSavedSearchFacts
    {
        public class GetCaseSavedSearchData : FactBase
        {
            [Fact]
            public void ReturnsExceptionIfXmlFilterCriteriaNotPassed()
            {
                var fixture = new CaseSavedSearchFixture();
                Assert.Throws<HttpException>(() => { fixture.Subject.GetCaseSavedSearchData(null); });
            }

            [Fact]
            public void ReturnsExceptionIfXmlFilterCriteriaNotValid()
            {
                var fixture = new CaseSavedSearchFixture();
                Assert.Throws<HttpException>(() => { fixture.Subject.GetCaseSavedSearchData("<a></a>"); });
                Assert.Throws<HttpException>(() => { fixture.Subject.GetCaseSavedSearchData("a"); });
            }

            [Fact]
            public void ReturnsCaseSearchFilterData()
            {
                var fixture = new CaseSavedSearchFixture();

                var filterCriteria = @"<Search><Report><ReportTitle>AU</ReportTitle></Report><Filtering><csw_ListCase>
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

                var data = (List<CaseSavedSearch.Step>)fixture.Subject.GetCaseSavedSearchData(filterCriteria);
                Assert.NotNull(data);
                Assert.Equal(3, data.Count);
                Assert.Equal(1, data[0].Id);
                Assert.Equal("AND", data[0].Operator);
                Assert.Equal(1, data[0].Id);
                Assert.Equal("AND", data[0].Operator);
                Assert.False(data[0].IsAdvancedSearch);
                Assert.True(data[0].IsDefault);
                Assert.True(data[0].Selected);
                Assert.Contains(fixture.RefTopic, data[0].TopicsData);
                Assert.Contains(fixture.DetailsTopic, data[0].TopicsData);
                Assert.Contains(fixture.NamesTopic, data[0].TopicsData);

                Assert.Equal(2, data[1].Id);
                Assert.Equal("OR", data[1].Operator);
                Assert.Equal(2, data[1].Id);
                Assert.False(data[1].IsAdvancedSearch);
                Assert.False(data[1].IsDefault);
                Assert.False(data[1].Selected);

                Assert.Equal(3, data[2].Id);
                Assert.Equal(3, data[2].Id);
                Assert.Equal("OR", data[2].Operator);
                Assert.False(data[2].IsAdvancedSearch);

            }
        }

        public class CaseSavedSearchFixture : IFixture<CaseSavedSearch>
        {
            public CaseSavedSearchFixture()
            {
                RefTopic = new CaseSavedSearch.Topic("References")
                {
                    FormData = new ReferencesTopic()
                };
                DetailsTopic = new CaseSavedSearch.Topic("Details")
                {
                    FormData = new DetailsTopic()
                };
                NamesTopic = new CaseSavedSearch.Topic("Names")
                {
                    FormData = new NamesTopic()
                };

                ReferencesTopicBuilder = Substitute.For<ITopicBuilder>();
                ReferencesTopicBuilder?.Build(Arg.Any<XElement>()).Returns(RefTopic);

                DetailsTopicBuilder = Substitute.For<ITopicBuilder>();
                DetailsTopicBuilder?.Build(Arg.Any<XElement>()).Returns(DetailsTopic);

                NamesTopicBuilder = Substitute.For<ITopicBuilder>();
                NamesTopicBuilder?.Build(Arg.Any<XElement>()).Returns(NamesTopic);

                TopicBuilders = new[] { ReferencesTopicBuilder, DetailsTopicBuilder, NamesTopicBuilder };

                Subject = new CaseSavedSearch(TopicBuilders,DueDate);
            }

            public IEnumerable<ITopicBuilder> TopicBuilders { get; set; }

            public DueDateBuilder DueDate { get; set; }

            public ITopicBuilder NamesTopicBuilder { get; set; }
            public ITopicBuilder ReferencesTopicBuilder { get; set; }
            public ITopicBuilder DetailsTopicBuilder { get; set; }

            public CaseSavedSearch Subject { get; set; }

            public CaseSavedSearch.Topic RefTopic { get; set; }
            public CaseSavedSearch.Topic DetailsTopic { get; set; }
            public CaseSavedSearch.Topic NamesTopic { get; set; }
        }
    }
}
