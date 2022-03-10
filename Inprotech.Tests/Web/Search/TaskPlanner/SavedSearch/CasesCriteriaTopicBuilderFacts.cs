using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search.TaskPlanner.SavedSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner.SavedSearch
{
    public class CasesCriteriaTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }
            [Fact]
            public void ReturnsDefaultValueForCasesCriteriaTopic()
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

                var fixture = new CasesCriteriaTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("cases", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicFormData = (CasesSection)topic.FormData;
                Assert.Equal("2", topicFormData.CaseReference.Operator);
                Assert.Null(topicFormData.CaseReference.Value);
                Assert.Equal("0", topicFormData.OfficialNumber.Operator);
                Assert.Null(topicFormData.OfficialNumber.Value);
                Assert.Equal("0", topicFormData.CaseFamily.Operator);
                Assert.NotNull(topicFormData.CaseFamily.Value);
                Assert.Equal("0", topicFormData.CaseList.Operator);
                Assert.Null(topicFormData.CaseList.Value);
                Assert.Equal("0", topicFormData.CaseOffice.Operator);
                Assert.Null(topicFormData.CaseOffice.Value);
                Assert.Equal("0", topicFormData.Instructor.Operator);
                Assert.Null(topicFormData.Instructor.Value);
                Assert.True(topicFormData.IsPending);
                Assert.True(topicFormData.IsRegistered);
                Assert.True(topicFormData.IsDead);

            }

            [Fact]
            public void ReturnsTopicWhenCasesCriteriaTopicHasPicklist()
            {
                new CaseBuilder().BuildWithId(-487).In(Db);
                new CaseBuilder().BuildWithId(-486).In(Db);
                new CaseBuilder().BuildWithId(-494).In(Db);
                new CaseList(2, "Case List 1") { Description = "Case List 1 Desc" }.In(Db);
                new Family("BALLOON", "BALLOON").In(Db);
                new Family("BWU", "BWU").In(Db);
                new Office(1, "noida").In(Db);
                var fixture = new CasesCriteriaTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(GetElement()));
                Assert.Equal("cases", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var topicFormData = topic.FormData;
                Assert.NotNull(topicFormData);
                Assert.NotNull(topicFormData.CaseList);
                Assert.Equal("2", topicFormData.CaseReference.Operator);
                Assert.Equal("sss", topicFormData.CaseReference.Value);
                Assert.Equal("0", topicFormData.OfficialNumber.Operator);
                Assert.Equal("sss", topicFormData.OfficialNumber.Value);
                Assert.Equal("0", topicFormData.CaseFamily.Operator);
                Assert.NotNull(topicFormData.CaseFamily.Value);
                Assert.Equal("0", topicFormData.CaseList.Operator);
                Assert.Null(topicFormData.CaseList.Value);
                Assert.Equal("0", topicFormData.CaseOffice.Operator);
                Assert.NotNull(topicFormData.CaseOffice.Value);
                Assert.Equal("0", topicFormData.Instructor.Operator);
                Assert.NotNull(topicFormData.Instructor.Value);
                Assert.True(topicFormData.IsPending);
                Assert.True(topicFormData.IsRegistered);
                Assert.False(topicFormData.IsDead);

            }
            public string GetElement()
            {
                string element = @"  
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
            <CaseReference Operator='2'>sss</CaseReference>
            <OfficialNumber Operator='0' UseRelatedCase='0' UseCurrent='0'>
               <Number UseNumericSearch='0'>sss</Number>
               <TypeKey />
            </OfficialNumber>
            <FamilyKeyList Operator='0'>
               <FamilyKey>BWU</FamilyKey>
            </FamilyKeyList>
            <CaseList Operator='0'>0</CaseList>
            <OfficeKeys Operator='0'>10175</OfficeKeys>
            <CountryKeys Operator='0'>AF</CountryKeys>
            <CaseTypeKeys Operator='0'>E</CaseTypeKeys>
            <CategoryKey Operator='0'>N</CategoryKey>
            <SubTypeKey Operator='0'>C</SubTypeKey>
            <PropertyTypeKeys Operator='0'>B</PropertyTypeKeys>
            <OwnerKeys Operator='0'>10077</OwnerKeys>
            <InstructorKeys Operator='0'>10054</InstructorKeys>
            <EventKeys Operator='1'>-1011349,-1011348,-1011346</EventKeys>
            <EventCategoryKeys Operator='1'>5,11</EventCategoryKeys>
            <EventGroupKeys Operator='0'>14202,14203,21024</EventGroupKeys>
            <EventNoteTypeKeys Operator='1'>3</EventNoteTypeKeys>
            <EventNoteText Operator='2'>wwww</EventNoteText>
            <Actions IsRenewalsOnly='0' IsNonRenewalsOnly='0' IncludeClosed='1'>
               <ActionKeys Operator='0'>AC,PF</ActionKeys>
            </Actions>
            <OtherNameTypeKeys Operator='0'>10077</OtherNameTypeKeys>
            <StatusFlags CheckDeadCaseRestriction='0'>
               <IsPending>1</IsPending>
               <IsRegistered>1</IsRegistered>
               <IsDead>0</IsDead>
            </StatusFlags>
            <StatusKey Operator='0'>-297</StatusKey>
            <RenewalStatusKey Operator='0'>-221</RenewalStatusKey>
         </FilterCriteria>";

                return element;
            }

        }
    }
    public class CasesCriteriaTopicBuilderFixture : IFixture<CasesCriteriaTopicBuilder>
    {
        public CasesCriteriaTopicBuilderFixture(InMemoryDbContext db)
        {
            Basis = Substitute.For<IBasis>();
            CaseTypes = Substitute.For<ICaseTypes>();
            SubTypes = Substitute.For<ISubTypes>();
            CaseCategories = Substitute.For<ICaseCategories>();
            PropertyTypes = Substitute.For<IPropertyTypes>();
            CaseStatuses = Substitute.For<ICaseStatuses>();

            Subject = new CasesCriteriaTopicBuilder(db, CaseTypes, Basis, SubTypes, CaseCategories, PropertyTypes, CaseStatuses);

        }

        public IBasis Basis { get; set; }
        public ICaseTypes CaseTypes { get; set; }
        public ISubTypes SubTypes { get; set; }
        public ICaseCategories CaseCategories { get; set; }
        public IPropertyTypes PropertyTypes { get; set; }
        public ICaseStatuses CaseStatuses { get; set; }
        public CasesCriteriaTopicBuilder Subject { get; set; }
    }
}
