using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search.TaskPlanner.SavedSearch;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner.SavedSearch
{
    public class EventsAndActionsTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }
            [Fact]
            public void ReturnsDefaultValueForEventAndActionTopic()
            {
                const string filterCriteria = @"  
         <FilterCriteria>
            <Include>
               <IsReminders>1</IsReminders>
               <IsDueDates>0</IsDueDates>
               <IsAdHocDates>1</IsAdHocDates>
            </Include>
            <BelongsTo>
               <NameKey Operator='0' IsCurrentUser='1' />
               <ActingAs IsReminderRecipient='1' IsResponsibleStaff='1'>
                  <NameTypeKey>SIG</NameTypeKey>
                  <NameTypeKey>EMP</NameTypeKey>
               </ActingAs>
            </BelongsTo>
            <Dates UseDueDate='1' UseReminderDate='1'>
               <PeriodRange Operator='7'>
                  <Type>W</Type>
                  <From>-4</From>
                  <To>2</To>
               </PeriodRange>
            </Dates>
         </FilterCriteria>";

                var fixture = new EventsAndActionsTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("eventsAndActions", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicFormData = (EventAndActions)topic.FormData;
                Assert.Equal("0", topicFormData.Action.Operator);
                Assert.NotNull(topicFormData.Action.Value);
                Assert.Equal("0", topicFormData.Event.Operator);
                Assert.NotNull(topicFormData.Event.Value);
                Assert.Equal("0", topicFormData.EventCategory.Operator);
                Assert.NotNull(topicFormData.EventCategory.Value);
                Assert.Equal("0", topicFormData.EventGroup.Operator);
                Assert.NotNull(topicFormData.EventGroup.Value);
                Assert.Equal("2", topicFormData.EventNotes.Operator);
                Assert.Null(topicFormData.EventNotes.Value);
                Assert.Equal("0", topicFormData.EventNoteType.Operator);
                Assert.NotNull(topicFormData.EventNoteType.Value);
                Assert.False(topicFormData.IsClosed);
                Assert.True(topicFormData.IsNonRenewals);
                Assert.True(topicFormData.IsRenewals);

            }

            [Fact]
            public void ReturnsSavedValueForEventAndActionTopic()
            {
                const string filterCriteria = @"
         <FilterCriteria>
            <Include>
               <IsReminders>1</IsReminders>
               <IsDueDates>0</IsDueDates>
               <IsAdHocDates>1</IsAdHocDates>
               <HasCase>1</HasCase>
               <HasName>1</HasName>
               <IsGeneral>1</IsGeneral>
            </Include>
            <BelongsTo>
               <NameKey Operator='0' IsCurrentUser='1' />
               <ActingAs IsReminderRecipient='1' IsResponsibleStaff='1'>
                  <NameTypeKey>EMP</NameTypeKey>
                  <NameTypeKey>SIG</NameTypeKey>
               </ActingAs>
            </BelongsTo>
            <Dates UseDueDate='1' UseReminderDate='1' SinceLastWorkingDay='0'>
               <PeriodRange Operator='7'>
                  <Type>W</Type>
                  <From>-4</From>
                  <To>2</To>
               </PeriodRange>
            </Dates>
            <EventKeys Operator='1'>-1011351,-1011785</EventKeys>
            <EventCategoryKeys Operator='1'>5</EventCategoryKeys>
            <EventGroupKeys Operator='0'>14203,21024,14202</EventGroupKeys>
            <EventNoteTypeKeys Operator='1'>3</EventNoteTypeKeys>
            <EventNoteText Operator='2'>wwww</EventNoteText>
            <Actions IsRenewalsOnly='0' IsNonRenewalsOnly='0' IncludeClosed='1'>
               <ActionKeys Operator='0'>PF,AC</ActionKeys>
            </Actions>
            <StatusFlags CheckDeadCaseRestriction='0'>
               <IsPending>1</IsPending>
               <IsRegistered>1</IsRegistered>
               <IsDead>0</IsDead>
            </StatusFlags>
         </FilterCriteria>";
                new EventBuilder { Id = -1011351, Code = "1 Month Formal Matter - Last Day" }.Build().In(Db);
                new EventBuilder { Id = -1011785, Code = "2 Month Formal Matter - Last Day" }.Build().In(Db);
                new InprotechKaizen.Model.Cases.Events.EventCategory((short)5).In(Db);
                var fixture = new EventsAndActionsTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("eventsAndActions", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicFormData = (EventAndActions)topic.FormData;
                Assert.Equal("1 Month Formal Matter - Last Day", topicFormData.Event.Value[0].Code);
                Assert.Equal("2 Month Formal Matter - Last Day", topicFormData.Event.Value[1].Code);
                Assert.False(topicFormData.IsNonRenewals);
                Assert.False(topicFormData.IsRenewals);

            }
        }

    }
    public class EventsAndActionsTopicBuilderFixture : IFixture<EventsAndActionsTopicBuilder>
    {
        public EventsAndActionsTopicBuilderFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Actions = Substitute.For<IActions>();

            Subject = new EventsAndActionsTopicBuilder(db, PreferredCultureResolver, Actions);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IActions Actions { get; set; }

        public EventsAndActionsTopicBuilder Subject { get; set; }
    }
}
