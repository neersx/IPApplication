using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using NSubstitute;
using System.Xml.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class DataManagementTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }

            [Fact]
            public void ReturnsDefaultOperatorsForDataManagementTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter></FilterCriteria>";

                var fixture = new DataManagementTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("dataManagement", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicData = (DataManagementTopic) topic.FormData;
                Assert.Null(topicData.BatchIdentifier);
                Assert.Null(topicData.DataSource);
                Assert.Null(topicData.SentToCPA);
            }

            [Fact]
            public void ReturnsValuesForDataManagementTopic()
            {
                var n1 = new NameBuilder(Db).Build().In(Db);
                var aliasType = new NameAliasType {Code = KnownAliasTypes.EdeIdentifier}.In(Db);
                new NameAliasBuilder(Db) {AliasType = aliasType, Name = n1}.Build().In(Db);
                var batchIdentifier = Fixture.String("BayNo");
                var sentToCpa = Fixture.Integer();

                var filterCriteria = "<FilterCriteria ID='1'>" +
                                         "<EDEBatchIdentifier>"+ batchIdentifier +"</EDEBatchIdentifier>" +
                                         "<EDEDataSourceNameNo>"+ n1.Id +"</EDEDataSourceNameNo>" +
                                         "<CPASentBatchNo Operator='0'>"+sentToCpa+"</CPASentBatchNo>" +
                                     "</FilterCriteria>";
                
                var fixture = new DataManagementTopicBuilderFixture(Db);
                fixture.AccessSecurity.CanView(n1).Returns(true);

                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("dataManagement", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var dmTopic = (DataManagementTopic) topic.FormData;
                
                Assert.Equal(batchIdentifier ,dmTopic.BatchIdentifier);
                Assert.Equal(n1.Id, dmTopic.DataSource?.Key);
                Assert.Equal(sentToCpa, dmTopic.SentToCPA);
            }
        }

        public class DataManagementTopicBuilderFixture : IFixture<DataManagementTopicBuilder>
        {
            public DataManagementTopicBuilderFixture(InMemoryDbContext db)
            {
                AccessSecurity = Substitute.For<INameAccessSecurity>();

                Subject = new DataManagementTopicBuilder(db, AccessSecurity);
            }

            public INameAccessSecurity AccessSecurity { get; set; }

            public DataManagementTopicBuilder Subject { get; set; }
        }
    }
}
