using System.Xml.Linq;
using Inprotech.Web.Search.TaskPlanner.SavedSearch;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner.SavedSearch
{
    public class RemindersTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }

            [Fact]
            public void ReturnsDefaultValueForRemindersTopic()
            {
                const string filterCriteria = @"  
         <FilterCriteria>
           <ReminderMessage Operator='2'>dataset</ReminderMessage>
         </FilterCriteria>";

                var fixture = new RemindersTopicBuilderFixture();
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("reminders", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicFormData = (RemindersSection)topic.FormData;
                Assert.Equal("2", topicFormData.ReminderMessage.Operator);
                Assert.Equal(true, topicFormData.IsOnHold);
                Assert.Equal(true, topicFormData.IsNotOnHold);
                Assert.Equal(true, topicFormData.IsRead);
                Assert.Equal(true, topicFormData.IsNotRead);
            }
            [Fact]
            public void ReturnsHoldAndReadValueOnFalseValueForRemindersTopic()
            {
                const string filterCriteria = @"  
         <FilterCriteria>
           <ReminderMessage Operator='2'>dataset</ReminderMessage>
            <IsReminderOnHold>0</IsReminderOnHold>
            <IsReminderRead>0</IsReminderRead>
         </FilterCriteria>";

                var fixture = new RemindersTopicBuilderFixture();
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("reminders", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicFormData = (RemindersSection)topic.FormData;
                Assert.Equal("2", topicFormData.ReminderMessage.Operator);
                Assert.Equal(false, topicFormData.IsOnHold);
                Assert.Equal(true, topicFormData.IsNotOnHold);
                Assert.Equal(false, topicFormData.IsRead);
                Assert.Equal(true, topicFormData.IsNotRead);
            }
            [Fact]
            public void ReturnsHoldAndReadValueOnTrueForRemindersTopic()
            {
                const string filterCriteria = @"  
         <FilterCriteria>
           <ReminderMessage Operator='2'>dataset</ReminderMessage>
            <IsReminderOnHold>1</IsReminderOnHold>
            <IsReminderRead>1</IsReminderRead>
         </FilterCriteria>";

                var fixture = new RemindersTopicBuilderFixture();
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("reminders", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicFormData = (RemindersSection)topic.FormData;
                Assert.Equal("2", topicFormData.ReminderMessage.Operator);
                Assert.Equal(true, topicFormData.IsOnHold);
                Assert.Equal(false, topicFormData.IsNotOnHold);
                Assert.Equal(true, topicFormData.IsRead);
                Assert.Equal(false, topicFormData.IsNotRead);
            }
            [Fact]
            public void ReturnsReadValueOnfalseForRemindersTopic()
            {
                const string filterCriteria = @"  
         <FilterCriteria>
           <ReminderMessage Operator='2'>dataset</ReminderMessage>
            <IsReminderRead>0</IsReminderRead>
         </FilterCriteria>";

                var fixture = new RemindersTopicBuilderFixture();
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("reminders", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicFormData = (RemindersSection)topic.FormData;
                Assert.Equal("2", topicFormData.ReminderMessage.Operator);
                Assert.Equal(true, topicFormData.IsOnHold);
                Assert.Equal(true, topicFormData.IsNotOnHold);
                Assert.Equal(false, topicFormData.IsRead);
                Assert.Equal(true, topicFormData.IsNotRead);
            }
        }
    }

    public class RemindersTopicBuilderFixture : IFixture<RemindersTopicBuilder>
    {
        public RemindersTopicBuilderFixture()
        {
            Subject = new RemindersTopicBuilder();
        }

        public RemindersTopicBuilder Subject { get; set; }
    }
}