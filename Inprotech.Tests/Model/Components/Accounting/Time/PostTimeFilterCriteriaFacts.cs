using System;
using System.Collections.Generic;
using System.Xml.Linq;
using InprotechKaizen.Model.Components.Accounting.Time;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Time
{
    public class PostTimeFilterCriteriaFacts
    {

        [Fact]
        public void ShouldBuildWithEntityKey()
        {
            var entityKey = Fixture.Integer();

            var filterCriteriaXml = new PostTimeFilterCriteria
            {
                WipEntityId = entityKey
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<ts_PostTime><ts_ListDiary><FilterCriteria><StaffKey Operator=\"0\" IsCurrentUser=\"0\" /><EntryType><IsUnposted>0</IsUnposted><IsContinued>0</IsContinued><IsIncomplete>0</IsIncomplete><IsPosted>0</IsPosted><IsTimer>0</IsTimer></EntryType></FilterCriteria></ts_ListDiary><WipEntityKey>{entityKey}</WipEntityKey></ts_PostTime>", filterCriteriaXml);
        }

        [Fact]
        public void ShouldBuildWithStaffNameKey()
        {
            var entityKey = Fixture.Integer();
            var staffNameKey = Fixture.Integer();

            var filterCriteriaXml = new PostTimeFilterCriteria
            {
                StaffFilter = new PostTimeFilterCriteria.StaffFilterCriteria
                {
                    StaffNameId = staffNameKey,
                    IsCurrentUser = true
                },
                WipEntityId = entityKey
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<ts_PostTime><ts_ListDiary><FilterCriteria><StaffKey Operator=\"0\" IsCurrentUser=\"1\">{staffNameKey}</StaffKey><EntryType><IsUnposted>0</IsUnposted><IsContinued>0</IsContinued><IsIncomplete>0</IsIncomplete><IsPosted>0</IsPosted><IsTimer>0</IsTimer></EntryType></FilterCriteria></ts_ListDiary><WipEntityKey>{entityKey}</WipEntityKey></ts_PostTime>", filterCriteriaXml);
        }

        [Fact]
        public void ShouldBuildForPostingTime()
        {
            var entityKey = Fixture.Integer();
            var staffNameKey = Fixture.Integer();

            var filterCriteriaXml = new PostTimeFilterCriteria
            {
                StaffFilter = new PostTimeFilterCriteria.StaffFilterCriteria
                {
                    StaffNameId = staffNameKey,
                    IsCurrentUser = true
                },
                WipEntityId = entityKey
            }.ValidForPosting().Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<ts_PostTime><ts_ListDiary><FilterCriteria><StaffKey Operator=\"0\" IsCurrentUser=\"1\">{staffNameKey}</StaffKey><EntryType><IsUnposted>1</IsUnposted><IsContinued>0</IsContinued><IsIncomplete>1</IsIncomplete><IsPosted>0</IsPosted><IsTimer>0</IsTimer></EntryType></FilterCriteria></ts_ListDiary><WipEntityKey>{entityKey}</WipEntityKey></ts_PostTime>", filterCriteriaXml);
        }

        [Fact]
        public void BuildsFilterForSelectedEntryNumbers()
        {
            var entityKey = Fixture.Integer();
            var staffNameKey = Fixture.Integer();
            var entryNos = new List<int> { Fixture.Integer(), Fixture.Short(), Fixture.Integer() };

            var filterCriteriaXml = new PostTimeFilterCriteria
            {
                StaffFilter = new PostTimeFilterCriteria.StaffFilterCriteria
                {
                    StaffNameId = staffNameKey,
                    IsCurrentUser = true
                },
                EntryNos = entryNos,
                WipEntityId = entityKey
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<ts_PostTime><ts_ListDiary><FilterCriteria><StaffKey Operator=\"0\" IsCurrentUser=\"1\">{staffNameKey}</StaffKey><EntryType><IsUnposted>0</IsUnposted><IsContinued>0</IsContinued><IsIncomplete>0</IsIncomplete><IsPosted>0</IsPosted><IsTimer>0</IsTimer></EntryType><EntryNumbers>{string.Join(",", entryNos)}</EntryNumbers></FilterCriteria></ts_ListDiary><WipEntityKey>{entityKey}</WipEntityKey></ts_PostTime>", filterCriteriaXml);
        }

        [Fact]
        public void BuildsFilterForSelectedDates()
        {
            var entityKey = Fixture.Integer();
            var staffNameKey = Fixture.Integer();
            var selectedDates = new List<DateTime> { Fixture.PastDate(), Fixture.Today(), Fixture.FutureDate() };

            var filterCriteriaXml = new PostTimeFilterCriteria
            {
                StaffFilter = new PostTimeFilterCriteria.StaffFilterCriteria
                {
                    StaffNameId = staffNameKey,
                    IsCurrentUser = true
                },
                EntryDates = selectedDates,
                WipEntityId = entityKey
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<ts_PostTime><ts_ListDiary><FilterCriteria><StaffKey Operator=\"0\" IsCurrentUser=\"1\">{staffNameKey}</StaffKey><EntryType><IsUnposted>0</IsUnposted><IsContinued>0</IsContinued><IsIncomplete>0</IsIncomplete><IsPosted>0</IsPosted><IsTimer>0</IsTimer></EntryType><EntryDateGroup Operator=\"0\"><Date>{Fixture.PastDate():yyyy-MM-dd}</Date><Date>{Fixture.Today():yyyy-MM-dd}</Date><Date>{Fixture.FutureDate():yyyy-MM-dd}</Date></EntryDateGroup></FilterCriteria></ts_ListDiary><WipEntityKey>{entityKey}</WipEntityKey></ts_PostTime>", filterCriteriaXml);
        }

        [Fact]
        public void BuildsFilterForSelectedDateRange()
        {
            var entityKey = Fixture.Integer();
            var staffNameKey = Fixture.Integer();

            var filterCriteriaXml = new PostTimeFilterCriteria
            {
                StaffFilter = new PostTimeFilterCriteria.StaffFilterCriteria
                {
                    StaffNameId = staffNameKey,
                    IsCurrentUser = true
                },
                DateRange = new PostTimeFilterCriteria.DateRangeCriteria
                {
                    ToDate = Fixture.PastDate()
                },
                WipEntityId = entityKey
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<ts_PostTime><ts_ListDiary><FilterCriteria><StaffKey Operator=\"0\" IsCurrentUser=\"1\">{staffNameKey}</StaffKey><EntryType><IsUnposted>0</IsUnposted><IsContinued>0</IsContinued><IsIncomplete>0</IsIncomplete><IsPosted>0</IsPosted><IsTimer>0</IsTimer></EntryType><EntryDate><DateRange Operator=\"7\"><To>{Fixture.PastDate():yyyy-MM-dd}T00:00:00</To></DateRange></EntryDate></FilterCriteria></ts_ListDiary><WipEntityKey>{entityKey}</WipEntityKey></ts_PostTime>", filterCriteriaXml);
        }   

        [Fact]
        public void DoesNotBuildStaffIfNotProvided()
        {
            var entityKey = Fixture.Integer();

            var filterCriteriaXml = new PostTimeFilterCriteria
            {
                StaffFilter = null,
                DateRange = new PostTimeFilterCriteria.DateRangeCriteria
                {
                    ToDate = Fixture.PastDate()
                },
                WipEntityId = entityKey
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<ts_PostTime><ts_ListDiary><FilterCriteria><EntryType><IsUnposted>0</IsUnposted><IsContinued>0</IsContinued><IsIncomplete>0</IsIncomplete><IsPosted>0</IsPosted><IsTimer>0</IsTimer></EntryType><EntryDate><DateRange Operator=\"7\"><To>{Fixture.PastDate():yyyy-MM-dd}T00:00:00</To></DateRange></EntryDate></FilterCriteria></ts_ListDiary><WipEntityKey>{entityKey}</WipEntityKey></ts_PostTime>", filterCriteriaXml);
        }   
    }
}
