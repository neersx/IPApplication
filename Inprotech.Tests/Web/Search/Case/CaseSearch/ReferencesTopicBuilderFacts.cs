using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class ReferencesTopicBuilderFacts : FactBase
    {
        [Fact]
        public void ReturnsTopicWithDefaultValue()
        {
            var f = new ReferencesTopicBuilderFixture(Db);
            var topic = f.Subject.Build(f.GetDefaultFilterCriteria());

            Assert.Equal("References", topic.TopicKey);
            Assert.NotNull(topic.FormData);
            var referencesTopic = topic.FormData as ReferencesTopic;
            Assert.NotNull(referencesTopic);
            Assert.Equal(1, referencesTopic.Id);
            Assert.Empty(referencesTopic.CaseKeys);
            Assert.Null(referencesTopic.CaseList);
            Assert.Equal(Operators.EqualTo, referencesTopic.CaseListOperator);
            Assert.Null(referencesTopic.CaseNameReference);
            Assert.Equal(Operators.StartsWith, referencesTopic.CaseNameReferenceOperator);
            Assert.Null(referencesTopic.CaseNameReferenceType);
            Assert.Null(referencesTopic.CaseReference);
            Assert.Equal(Operators.StartsWith, referencesTopic.CaseReferenceOperator);
            Assert.Null(referencesTopic.Family);
            Assert.Equal(Operators.EqualTo, referencesTopic.FamilyOperator);
            Assert.False(referencesTopic.IsPrimeCasesOnly);
            Assert.Null(referencesTopic.OfficialNumber);
            Assert.Equal(Operators.EqualTo, referencesTopic.OfficialNumberOperator);
            Assert.Equal(string.Empty, referencesTopic.OfficialNumberType);
            Assert.Null(referencesTopic.YourReference);
            Assert.Equal(Operators.EqualTo, referencesTopic.YourReferenceOperator);
            Assert.False(referencesTopic.SearchNumbersOnly);
            Assert.False(referencesTopic.SearchRelatedCases);
        }

        [Fact]
        public void ReturnsTopicWhenCaseReferenceHasPicklist()
        {
            new CaseBuilder().BuildWithId(-487).In(Db);
            new CaseBuilder().BuildWithId(-486).In(Db);
            new CaseBuilder().BuildWithId(-494).In(Db);
            new CaseList(2, "Case List 1") {Description = "Case List 1 Desc"}.In(Db);
            new Family("BALLOON", "BALLOON").In(Db);
            new Family("BWU", "BWU").In(Db);
            var f = new ReferencesTopicBuilderFixture(Db);
            var topic = f.Subject.Build(f.GetFilterCriteriaWhenCaseReferenceHasPicklist());
            Assert.Equal("References", topic.TopicKey);
            Assert.NotNull(topic.FormData);
            var referencesTopic = topic.FormData as ReferencesTopic;
            Assert.NotNull(referencesTopic);
            Assert.Equal(1, referencesTopic.Id);
            Assert.NotNull(referencesTopic.CaseKeys);
            Assert.Equal(3,referencesTopic.CaseKeys.Length);
            Assert.NotNull(referencesTopic.CaseList);
            Assert.Equal(Operators.NotEqualTo, referencesTopic.CaseListOperator);
            Assert.Null(referencesTopic.CaseReference);
            Assert.Equal(Operators.EqualTo, referencesTopic.CaseReferenceOperator);
            Assert.Equal("xyz",referencesTopic.CaseNameReference);
            Assert.Equal(Operators.EndsWith, referencesTopic.CaseNameReferenceOperator);
            Assert.Equal("I", referencesTopic.CaseNameReferenceType);
            Assert.Equal(2, referencesTopic.Family.Length);
            Assert.Equal(Operators.EqualTo, referencesTopic.FamilyOperator);
            Assert.True(referencesTopic.IsPrimeCasesOnly);
            Assert.Equal("1234",referencesTopic.OfficialNumber);
            Assert.Equal(Operators.StartsWith, referencesTopic.OfficialNumberOperator);
            Assert.Equal(string.Empty,referencesTopic.OfficialNumberType);
            Assert.Null(referencesTopic.YourReference);
            Assert.Equal(Operators.EqualTo, referencesTopic.YourReferenceOperator);
            Assert.False(referencesTopic.SearchNumbersOnly);
            Assert.False(referencesTopic.SearchRelatedCases);
        }

        [Fact]
        public void ReturnsTopicWhenCaseReferenceHasTextBox()
        {
            new CaseBuilder().BuildWithId(-487).In(Db);
            new CaseBuilder().BuildWithId(-486).In(Db);
            new CaseBuilder().BuildWithId(-494).In(Db);
            new CaseList(2, "Case List 1") {Description = "Case List 1 Desc"}.In(Db);
            new Family("BALLOON", "BALLOON").In(Db);
            new Family("BWU", "BWU").In(Db);
            var f = new ReferencesTopicBuilderFixture(Db);
            var topic = f.Subject.Build(f.GetFilterCriteriaWhenCaseReferenceHasTextBox());
            Assert.Equal("References", topic.TopicKey);
            Assert.NotNull(topic.FormData);
            var referencesTopic = topic.FormData as ReferencesTopic;
            Assert.NotNull(referencesTopic);
            Assert.Equal(1, referencesTopic.Id);
            Assert.Empty(referencesTopic.CaseKeys);
            Assert.NotNull(referencesTopic.CaseList);
            Assert.Equal(Operators.NotEqualTo, referencesTopic.CaseListOperator);
            Assert.Equal("1234",referencesTopic.CaseReference);
            Assert.Equal(Operators.StartsWith, referencesTopic.CaseReferenceOperator);
            Assert.Equal("xyz",referencesTopic.CaseNameReference);
            Assert.Equal(Operators.EndsWith, referencesTopic.CaseNameReferenceOperator);
            Assert.Equal("I", referencesTopic.CaseNameReferenceType);
            Assert.Equal(2, referencesTopic.Family.Length);
            Assert.Equal(Operators.EqualTo, referencesTopic.FamilyOperator);
            Assert.False(referencesTopic.IsPrimeCasesOnly);
            Assert.Equal("1234",referencesTopic.OfficialNumber);
            Assert.Equal(Operators.StartsWith, referencesTopic.OfficialNumberOperator);
            Assert.Equal(string.Empty,referencesTopic.OfficialNumberType);
            Assert.Null(referencesTopic.YourReference);
            Assert.Equal(Operators.EqualTo, referencesTopic.YourReferenceOperator);
            Assert.False(referencesTopic.SearchNumbersOnly);
            Assert.False(referencesTopic.SearchRelatedCases);
        }
    }

    public class ReferencesTopicBuilderFixture : IFixture<ReferencesTopicBuilder>
    {
        public ReferencesTopicBuilderFixture(InMemoryDbContext db)
        {
           
            Subject = new ReferencesTopicBuilder(db);
        }

        public ReferencesTopicBuilder Subject { get; }

        public XElement GetFilterCriteriaWhenCaseReferenceHasPicklist()
        {
            var xmlFilterCriteria = @"<Search>
   <Report>
      <ReportTitle>References</ReportTitle>
   </Report>
   <Filtering>
      <csw_ListCase>
         <FilterCriteriaGroup>
            <FilterCriteria ID='1'>
               <AccessMode>1</AccessMode>
               <IsAdvancedFilter>true</IsAdvancedFilter>
               <CaseKeys Operator='0'>-487,-494,-486</CaseKeys>
               <OfficialNumber Operator='2' UseCurrent='0' UseRelatedCase='0'>
                  <TypeKey />
                  <Number UseNumericSearch='0'>1234</Number>
               </OfficialNumber>
               <FamilyKey Operator='0'>BALLOON,BWU</FamilyKey>
               <CaseList IsPrimeCasesOnly='1'>
                  <CaseListKey Operator='1'>2</CaseListKey>                  
               </CaseList>
               <StandingInstructions IncludeInherited='0' />
               <StatusFlags CheckDeadCaseRestriction='1' />
               <CaseNameReference Operator='3'>
                  <TypeKey>I</TypeKey>
                  <ReferenceNo>xyz</ReferenceNo>
               </CaseNameReference>
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
        public XElement GetDefaultFilterCriteria()
        {
            var xmlFilterCriteria = @"<Search>
                   <Report>
                      <ReportTitle>blanktext</ReportTitle>
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

        public XElement GetFilterCriteriaWhenCaseReferenceHasTextBox()
        {
            var xmlFilterCriteria = @"<Search>
   <Report>
      <ReportTitle>References</ReportTitle>
   </Report>
   <Filtering>
      <csw_ListCase>
         <FilterCriteriaGroup>
            <FilterCriteria ID='1'>
               <AccessMode>1</AccessMode>
               <IsAdvancedFilter>true</IsAdvancedFilter>
               <CaseReference Operator='2'>1234</CaseReference>
               <OfficialNumber Operator='2' UseCurrent='0' UseRelatedCase='0'>
                  <TypeKey />
                  <Number UseNumericSearch='0'>1234</Number>
               </OfficialNumber>
               <FamilyKey Operator='0'>BALLOON,BWU</FamilyKey>
               <CaseList>
                  <CaseListKey Operator='1'>2</CaseListKey>
               </CaseList>
               <StandingInstructions IncludeInherited='0' />
               <StatusFlags CheckDeadCaseRestriction='1' />
               <CaseNameReference Operator='3'>
                  <TypeKey>I</TypeKey>
                  <ReferenceNo>xyz</ReferenceNo>
               </CaseNameReference>
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
}
