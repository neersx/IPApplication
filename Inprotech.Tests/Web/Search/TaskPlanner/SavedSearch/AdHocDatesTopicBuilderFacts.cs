using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search.TaskPlanner.SavedSearch;
using System.Xml.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner.SavedSearch
{
    public class AdHocDatesTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }

            [Fact]
            public void ReturnsValuesForAdHocTopic()
            {
                const string filterCriteria = @" <FilterCriteria>
            <Include>
               <HasCase>0</HasCase>
               <HasName>1</HasName>
               <IsGeneral>1</IsGeneral>
            </Include>
            <AdHocReference Operator='2'>12</AdHocReference>
            <NameReferenceKeys Operator='0'>-487</NameReferenceKeys>
            <AdHocMessage Operator='2'>Test Message</AdHocMessage>
            <AdHocEmailSubject Operator='2'>Email Subject</AdHocEmailSubject>
         </FilterCriteria>";
                new InprotechKaizen.Model.Names.Name(-487) {FirstName = "Staff", LastName = "Staff"}.In(Db);
                var fixture = new AdHocDatesTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("adhocDates", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var adhocTopic = (AdHocDates) topic.FormData;
                Assert.False(adhocTopic.IncludeCase);
                Assert.True(adhocTopic.IncludeName);
                Assert.True(adhocTopic.IncludeGeneral);
                Assert.NotNull(adhocTopic.Names); 
                Assert.Equal("0", adhocTopic.Names.Operator);
                Assert.Equal(-487, adhocTopic.Names.Value[0].Key);
                Assert.Equal("Staff, Staff", adhocTopic.Names.Value[0].DisplayName);
                Assert.Equal("2", adhocTopic.EmailSubject.Operator);
                Assert.Equal("Email Subject", adhocTopic.EmailSubject.Value);
                Assert.Equal("12",adhocTopic.GeneralRef.Value);
                Assert.Equal("2", adhocTopic.GeneralRef.Operator);
                Assert.Equal("2", adhocTopic.Message.Operator);
                Assert.Equal("Test Message", adhocTopic.Message.Value);
            }
        }

        public class AdHocDatesTopicBuilderFixture : IFixture<AdHocDatesTopicBuilder>
        {
            public AdHocDatesTopicBuilderFixture(InMemoryDbContext db)
            {
                Subject = new AdHocDatesTopicBuilder(db);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public AdHocDatesTopicBuilder Subject { get; set; }
        }
    }
}