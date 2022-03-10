using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class StatusTopicBuilderFacts
    {
          public class StatusTopicBuilderFixture : IFixture<StatusTopicBuilder>
        {
            public StatusTopicBuilderFixture()
            {
                CaseStatuses = Substitute.For<ICaseStatuses>();

                CaseStatuses.GetStatusByKeys("-200,-301").Returns(new List<StatusListItem>
                {
                    new StatusListItem {StatusKey = -200},
                    new StatusListItem {StatusKey = -301}
                });

                CaseStatuses.GetStatusByKeys("-224,-223").Returns(new List<StatusListItem>
                {
                    new StatusListItem {StatusKey = -224},
                    new StatusListItem {StatusKey = -223}
                });

                Subject = new StatusTopicBuilder(CaseStatuses);
            }

            public StatusTopicBuilder Subject { get; }

            public ICaseStatuses CaseStatuses { get; set; }
            
            public XElement GetFilterCriteriaWhenAllFieldsAreProvided()
            {
                var xmlFilterCriteria = @"<Search>
  <Report>
    <ReportTitle>Status</ReportTitle>
  </Report>
  <Filtering>
    <csw_ListCase>
      <FilterCriteriaGroup>
        <FilterCriteria ID='1'>
          <AccessMode>1</AccessMode>
          <IsAdvancedFilter>true</IsAdvancedFilter>
          <StatusKey Operator='0'>-200,-301</StatusKey>
          <RenewalStatusKey Operator='0'>-224,-223</RenewalStatusKey>
          <StandingInstructions IncludeInherited='0' />
          <StatusFlags CheckDeadCaseRestriction='1'>
            <IsPending>1</IsPending>
            <IsRegistered>1</IsRegistered>
            <IsDead>0</IsDead>
          </StatusFlags>
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
            
            public XElement GetDefaultFilterCriteria()
            {
                var xmlFilterCriteria = @"<Search>
  <Report>
    <ReportTitle>Status</ReportTitle>
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
          <Event Operator='' IsRenewalsOnly='0' IsNonRenewalsOnly='0' ByEventDate='1'>
            <Period>
              <Type>D</Type>
              <Quantity />
            </Period>
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
            public void ReturnsTextTopicWithDefaultValue()
            {
                var f = new StatusTopicBuilderFixture();
                var topicData = f.Subject.Build(f.GetDefaultFilterCriteria());

                Assert.Equal("Status",topicData.TopicKey);
                Assert.NotNull(topicData.FormData);
                var topic = topicData.FormData as StatusTopic;
                Assert.NotNull(topic);
                Assert.Equal(1, topic.Id);
                Assert.False(topic.IsPending);
                Assert.False(topic.IsRegistered);
                Assert.False(topic.IsDead);
                Assert.Empty(topic.CaseStatus);
                Assert.Equal(Operators.EqualTo, topic.CaseStatusOperator);
                Assert.Empty(topic.RenewalStatus);
                Assert.Equal(Operators.EqualTo,topic.RenewalStatusOperator);
            }

            [Fact]
            public void ReturnsTextTopicFormDataWhenKeyWordIsPicklist()
            {
                var f = new StatusTopicBuilderFixture();
                var topicData = f.Subject.Build(f.GetFilterCriteriaWhenAllFieldsAreProvided());

                Assert.Equal("Status",topicData.TopicKey);
                Assert.NotNull(topicData.FormData);
                var topic = topicData.FormData as StatusTopic;
                Assert.NotNull(topic);
                Assert.Equal(1, topic.Id);
                Assert.True(topic.IsPending);
                Assert.True(topic.IsRegistered);
                Assert.False(topic.IsDead);
                Assert.Equal(2,topic.CaseStatus.Length);
                Assert.Equal(-200,topic.CaseStatus.First().Key);
                Assert.Equal(Operators.EqualTo, topic.CaseStatusOperator);
                Assert.Equal(2, topic.RenewalStatus.Length);
                Assert.Equal(Operators.EqualTo,topic.RenewalStatusOperator);
                Assert.Equal(-224,topic.RenewalStatus.First().Key);
            }

        }
    }
}
