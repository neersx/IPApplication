using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class EventAndActionTopicBuilderFacts
    {
        public class EventsAndActionsTopicBuilderFixture : IFixture<EventsAndActionsTopicBuilder>
        {
            public EventsAndActionsTopicBuilder Subject { get; }
            
            public EventNoteTypeController EventNoteTypeController { get; set; }

            public IActions Actions { get; set; }
            
            public EventsAndActionsTopicBuilderFixture(InMemoryDbContext db)
            {
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                var securityConext = Substitute.For<ISecurityContext>();
                var parameters = new object[]{db, securityConext, preferredCultureResolver};
                EventNoteTypeController = Substitute.For<EventNoteTypeController>(parameters);
                Actions = Substitute.For<IActions>();
                Subject = new EventsAndActionsTopicBuilder(db,EventNoteTypeController, Actions);
            }
            
            public XElement GetFilterCriteriaWhenAllFieldsAreProvided()
            {
                var xmlFilterCriteria = @"<Search>
  <Report>
    <ReportTitle>Event</ReportTitle>
  </Report>
  <Filtering>
    <csw_ListCase>
      <FilterCriteriaGroup>
        <FilterCriteria ID='1'>
          <AccessMode>1</AccessMode>
          <IsAdvancedFilter>true</IsAdvancedFilter>
          <StandingInstructions IncludeInherited='0' />
          <StatusFlags CheckDeadCaseRestriction='1' />
          <InheritedName />
          <ActionKey Operator='1' IsOpen='1'>AL</ActionKey>
          <CaseNameGroup />
          <AttributeGroup BooleanOr='0' />
          <Event Operator='' IsRenewalsOnly='1' IsNonRenewalsOnly='1' ByDueDate='1' ByEventDate='1' IncludeClosedActions='1'>
            <EventKey>-1011351,-1011785</EventKey>
            <Period>
              <Type>D</Type>
              <Quantity />
            </Period>
            <ImportanceLevel Operator='8'>
              <From>7</From>
              <To>5</To>
            </ImportanceLevel>
            <EventNoteText Operator='4'>xyz</EventNoteText>
          </Event>
          <Actions />
        </FilterCriteria>
      </FilterCriteriaGroup>
      <ColumnFilterCriteria>
        <DueDates UseEventDates='1' UseAdHocDates='0'>
          <Dates UseDueDate='0' UseReminderDate='0' />
          <Actions IncludeClosed='0' IsRenewalsOnly='1' IsNonRenewalsOnly='1' />
          <DueDateResponsibilityOf IsAnyName='0' IsStaff='0' IsSignatory='0' />
        </DueDates>
      </ColumnFilterCriteria>
    </csw_ListCase>
  </Filtering>
</Search>";
                return GetFirstFilterCriteria(xmlFilterCriteria);
            }
            
            public XElement GetDefaultFilterCriteria()
            {
                var xmlFilterCriteria = @"<Search>
  <Report>
    <ReportTitle>Event</ReportTitle>
  </Report>
  <Filtering>
    <csw_ListCase>
      <FilterCriteriaGroup>
        <FilterCriteria ID='1'>
          <AccessMode>1</AccessMode>
          <IsAdvancedFilter>true</IsAdvancedFilter>
          <StandingInstructions IncludeInherited='0' />
          <StatusFlags CheckDeadCaseRestriction='1' />
          <InheritedName />
          <CaseNameGroup />
          <AttributeGroup BooleanOr='0' />
          <Event Operator='' IsRenewalsOnly='0' IsNonRenewalsOnly='0' ByEventDate='1' />
          <Actions />
        </FilterCriteria>
      </FilterCriteriaGroup>
      <ColumnFilterCriteria>
        <DueDates UseEventDates='1' UseAdHocDates='0'>
          <Dates UseDueDate='0' UseReminderDate='0' />
          <Actions IncludeClosed='0' IsRenewalsOnly='1' IsNonRenewalsOnly='1' />
          <DueDateResponsibilityOf IsAnyName='0' IsStaff='0' IsSignatory='0' />
        </DueDates>
      </ColumnFilterCriteria>
    </csw_ListCase>
  </Filtering>
</Search>";
                return GetFirstFilterCriteria(xmlFilterCriteria);
            }

            XElement GetFirstFilterCriteria(string xmlFilterCriteria)
            {
                var xDoc = XDocument.Parse(xmlFilterCriteria);
                var filterCriteria = xDoc.Descendants("FilterCriteriaGroup").First().Elements().First();
                return filterCriteria;
            }
        }

        public class BuildMethod : FactBase
        {
            [Fact]
            public void ReturnsEventsActionsTopicWithDefaultValue()
            {
                var f = new EventsAndActionsTopicBuilderFixture(Db);
                var topicData = f.Subject.Build(f.GetDefaultFilterCriteria());

                Assert.Equal("eventsActions",topicData.TopicKey);
                Assert.NotNull(topicData.FormData);
                var topic = topicData.FormData as EventsAndActionsTopic;
                Assert.NotNull(topic);
                Assert.Empty(topic.Event);
                Assert.True(topic.OccurredEvent);
                Assert.False(topic.DueEvent);
                Assert.False(topic.IncludeClosedActions);
                Assert.Equal(Operators.Between,topic.ImportanceLevelOperator);
                Assert.Null(topic.ImportanceLevelFrom);
                Assert.Null(topic.ImportanceLevelTo);
                Assert.Equal(Operators.EqualTo, topic.ActionOperator);
                Assert.Null(topic.ActionValue);
                Assert.False(topic.ActionIsOpen);
                Assert.False(topic.IsRenewals);
                Assert.False(topic.IsNonRenewals);
                Assert.Equal(Operators.EqualTo, topic.EventNotesOperator);
                Assert.Null(topic.EventNotesText);
                Assert.Empty(topic.EventNoteType);
                Assert.Null(topic.EventNoteTypeOperator);
            }

            [Fact]
            public void ReturnsEventsActionsTopicFormDataWhenCriteriaIsProvided()
            {
                new EventBuilder {Id = -1011351, Code = "1 Month Formal Matter - Last Day"}.Build().In(Db);
                new EventBuilder {Id = -1011785, Code = "2 Month Formal Matter - Last Day"}.Build().In(Db);

                var f = new EventsAndActionsTopicBuilderFixture(Db);
                f.Actions.GetActionByCode(Arg.Any<string>()).Returns( new ActionData()
                                                                     {
                                                                         Code = "AL"
                                                                     }
                                                                    );

                var topicData = f.Subject.Build(f.GetFilterCriteriaWhenAllFieldsAreProvided());
                Assert.Equal("eventsActions", topicData.TopicKey);
                Assert.NotNull(topicData.FormData);
                var topic = topicData.FormData as EventsAndActionsTopic;
                Assert.NotNull(topic);
                Assert.Equal(1, topic.Id);
                Assert.NotNull(topic);
                var events = topic.Event;
                Assert.Equal(2, events.Length);
                Assert.Equal("1 Month Formal Matter - Last Day", events.First().Code);
                Assert.True(topic.OccurredEvent);
                Assert.True(topic.DueEvent);
                Assert.True(topic.IncludeClosedActions);
                Assert.Equal(Operators.NotBetween,topic.ImportanceLevelOperator);
                Assert.Equal(Operators.Between,topic.ImportanceLevelFrom);
                Assert.Equal("5", topic.ImportanceLevelTo);
                Assert.Equal(Operators.NotEqualTo, topic.ActionOperator);
                Assert.NotNull(topic.ActionValue);
                Assert.Equal("AL", topic.ActionValue.Code);
                Assert.True(topic.ActionIsOpen);
                Assert.True(topic.IsRenewals);
                Assert.True(topic.IsNonRenewals);
                Assert.Equal(Operators.Contains, topic.EventNotesOperator);
                Assert.Equal("xyz", topic.EventNotesText);
                Assert.Empty(topic.EventNoteType);
                Assert.Null(topic.EventNoteTypeOperator);
            }
        }
    }
}
