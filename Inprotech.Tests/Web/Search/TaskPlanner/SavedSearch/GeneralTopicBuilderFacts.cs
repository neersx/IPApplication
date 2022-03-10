using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Search.TaskPlanner.SavedSearch;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner.SavedSearch
{
    public class GeneralTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }

            [Fact]
            public void ReturnsDefaultValueForGeneralTopic()
            {
                const string filterCriteria = @"  <FilterCriteria>
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

                var fixture = new GeneralTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("general", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var generalTopic = (General) topic.FormData;
                Assert.True(generalTopic.IncludeFilter.Reminders);
                Assert.True(generalTopic.IncludeFilter.AdHocDates);
                Assert.False(generalTopic.IncludeFilter.DueDates);
                Assert.Equal("myself", generalTopic.BelongingToFilter.Value);
                Assert.True(generalTopic.BelongingToFilter.ActingAs.IsDueDate);
                Assert.True(generalTopic.BelongingToFilter.ActingAs.IsReminder);
                Assert.NotNull(generalTopic.BelongingToFilter.ActingAs.NameTypes);
                Assert.Null(generalTopic.BelongingToFilter.NameGroups);
                Assert.Null(generalTopic.BelongingToFilter.Names);
                Assert.Equal("7", generalTopic.DateFilter.Operator);
                Assert.Null(generalTopic.DateFilter.DateRange.From);
                Assert.Null(generalTopic.DateFilter.DateRange.To);
                Assert.Equal("-4", generalTopic.DateFilter.DatePeriod.From);
                Assert.Equal("2", generalTopic.DateFilter.DatePeriod.To);
                Assert.Equal("W", generalTopic.DateFilter.DatePeriod.PeriodType);
                Assert.Equal("7", generalTopic.ImportanceLevel.Operator);
                Assert.Null(generalTopic.ImportanceLevel.From);
                Assert.Null(generalTopic.ImportanceLevel.To);
                Assert.True(generalTopic.SearchByFilter.DueDate);
                Assert.True(generalTopic.SearchByFilter.ReminderDate);
            }

            [Fact]
            public void ReturnsSavedSearchValueForGeneralTopic()
            {
                const string filterCriteria = @"<FilterCriteria>
            <Include>
               <IsReminders>1</IsReminders>
               <IsDueDates>0</IsDueDates>
               <IsAdHocDates>0</IsAdHocDates>
               <HasCase>1</HasCase>
               <HasName>1</HasName>
               <IsGeneral>1</IsGeneral>
            </Include>
            <BelongsTo>
               <NameKeys Operator='0'>-487,11</NameKeys>
               <ActingAs IsReminderRecipient='1' IsResponsibleStaff='0'>
                  <NameTypeKey>A</NameTypeKey>
                  <NameTypeKey>B</NameTypeKey>
               </ActingAs>
            </BelongsTo>
            <Dates UseDueDate='0' UseReminderDate='1' SinceLastWorkingDay='0'>
               <DateRange Operator='7'>
                  <From>2021-04-01T06:44:34Z</From>
                  <To>2021-04-10T06:44:34Z</To>
               </DateRange>
            </Dates>
            <ImportanceLevel Operator='8'>
               <From>1</From>
               <To>5</To>
            </ImportanceLevel>
            <Actions IsRenewalsOnly='1' IsNonRenewalsOnly='1' IncludeClosed='0' />
            <StatusFlags CheckDeadCaseRestriction='0'>
               <IsPending>1</IsPending>
               <IsRegistered>1</IsRegistered>
               <IsDead>0</IsDead>
            </StatusFlags>
         </FilterCriteria>";

                new InprotechKaizen.Model.Names.Name(11) {FirstName = "Signatory", LastName = "Signatory"}.In(Db);
                new InprotechKaizen.Model.Names.Name(-487) {FirstName = "Staff", LastName = "Staff"}.In(Db);
                new NameTypeBuilder {NameTypeCode = "A", Name = "Agent"}.Build().In(Db);
                new NameTypeBuilder {NameTypeCode = "B", Name = "Author"}.Build().In(Db);

                var fixture = new GeneralTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("general", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var generalTopic = (General) topic.FormData;
                Assert.True(generalTopic.IncludeFilter.Reminders);
                Assert.False(generalTopic.IncludeFilter.AdHocDates);
                Assert.False(generalTopic.IncludeFilter.DueDates);
                Assert.Equal("otherNames", generalTopic.BelongingToFilter.Value);
                Assert.False(generalTopic.BelongingToFilter.ActingAs.IsDueDate);
                Assert.True(generalTopic.BelongingToFilter.ActingAs.IsReminder);
                Assert.NotNull(generalTopic.BelongingToFilter.ActingAs.NameTypes);
                Assert.Equal("A", generalTopic.BelongingToFilter.ActingAs.NameTypes[0].Code);
                Assert.Equal("Author", generalTopic.BelongingToFilter.ActingAs.NameTypes[1].Value);
                Assert.NotNull(generalTopic.BelongingToFilter.Names);
                Assert.Equal(11, generalTopic.BelongingToFilter.Names[0].Key);
                Assert.Equal("Staff, Staff", generalTopic.BelongingToFilter.Names[1].DisplayName);
                Assert.Equal("7", generalTopic.DateFilter.Operator);
                Assert.Equal("2021-04-01T06:44:34Z", generalTopic.DateFilter.DateRange.From);
                Assert.Equal("2021-04-10T06:44:34Z", generalTopic.DateFilter.DateRange.To);
                Assert.Null(generalTopic.DateFilter.DatePeriod.From);
                Assert.Null(generalTopic.DateFilter.DatePeriod.To);
                Assert.Null(generalTopic.DateFilter.DatePeriod.PeriodType);
                Assert.Equal("8", generalTopic.ImportanceLevel.Operator);
                Assert.Equal("1", generalTopic.ImportanceLevel.From);
                Assert.Equal("5", generalTopic.ImportanceLevel.To);
                Assert.False(generalTopic.SearchByFilter.DueDate);
                Assert.True(generalTopic.SearchByFilter.ReminderDate);
            }
        }

        public class GeneralTopicBuilderFixture : IFixture<GeneralTopicBuilder>
        {
            public GeneralTopicBuilderFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new GeneralTopicBuilder(db, PreferredCultureResolver);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public GeneralTopicBuilder Subject { get; set; }
        }
    }
}