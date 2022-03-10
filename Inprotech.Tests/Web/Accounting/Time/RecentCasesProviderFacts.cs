using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class RecentCasesProviderFacts : FactBase
    {
        [Fact]
        public async Task ReturnsNullForNoMatches()
        {
            var f = new RecentCasesProviderFixture(Db);
            var result = await f.Subject.ForTimesheet(Fixture.Integer(), Fixture.Today());
            Assert.Empty(result);
        }

        [Fact]
        public async Task ReturnsForSpecifiedStaffOnly()
        {
            var staffId = Fixture.Integer();
            var toDate = Fixture.Today();
            var f = new RecentCasesProviderFixture(Db);

            new DiaryBuilder(Db) {StaffId = staffId + 1, EntityId = Fixture.Integer()}.BuildWithCase();
            Assert.Empty(await f.Subject.ForTimesheet(staffId, toDate));

            var staffEntry = new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer()}.BuildWithCase();

            var result = await f.Subject.ForTimesheet(staffId);
            var match = result.Single();
            Assert.True(staffEntry.CaseId == match.CaseKey && staffEntry.Case.Irn == match.CaseReference && staffEntry.Case.Title == match.Title);
        }

        [Fact]
        public async Task ReturnsCasesWorkedOnWithinSpecifiedDate()
        {
            var staffId = Fixture.Integer();
            var toDate = Fixture.Today();
            var f = new RecentCasesProviderFixture(Db);
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(2)}.BuildWithCase();
            var staffEntry = new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddHours(10)}.BuildWithCase();
            var result = await f.Subject.ForTimesheet(staffId, toDate.AddDays(1));
            Assert.Equal(staffEntry.CaseId, result.Single().CaseKey);

            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-10)}.BuildWithCase();
            result = await f.Subject.ForTimesheet(staffId, toDate.AddDays(1));
            Assert.Equal(2, result.Count());
        }

        [Fact]
        public async Task ReturnsDistinctCasesInMostRecentlyWorkedOrder()
        {
            var staffId = Fixture.Integer();
            var toDate = Fixture.Today();
            var f = new RecentCasesProviderFixture(Db);
            var case1 = new CaseBuilder().Build().In(Db);
            var case2 = new CaseBuilder().Build().In(Db);
            var case3 = new CaseBuilder().Build().In(Db);
            var instr1 = new NameBuilder(Db).Build().In(Db);
            var instr2 = new NameBuilder(Db).Build().In(Db);
            var instr3 = new NameBuilder(Db).Build().In(Db);
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(2), Case = case1, Instructor = instr1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddHours(2), Case = case1, Instructor = instr1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-2), Case = case2, Instructor = instr2}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddHours(2), Case = case2, Instructor = instr2}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-2), Case = case1, Instructor = instr1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(1), Case = case3, Instructor = instr3}.BuildWithCase();

            var result = (await f.Subject.ForTimesheet(staffId, toDate)).ToArray();
            Assert.Equal(2, result.Count());
            Assert.Equal(case1.Id, result.First().CaseKey);
            Assert.Equal(case2.Id, result.Last().CaseKey);
        }

        [Fact]
        public async Task ReturnsForSpecifiedInstructorNameKey()
        {
            var staffId = Fixture.Integer();
            var toDate = Fixture.Today();
            var f = new RecentCasesProviderFixture(Db);
            var case1 = new CaseBuilder().Build().In(Db);
            var case2 = new CaseBuilder().Build().In(Db);
            var case3 = new CaseBuilder().Build().In(Db);
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-32), Case = case1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddHours(-5), Case = case1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddHours(-80), Case = case2}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-1), Case = case3}.BuildWithCase();

            var name = case1.CaseNames.OrderBy(_ => _.Sequence).FirstOrDefault(_ => _.NameTypeId == "I");

            var result = (await f.Subject.ForTimesheet(staffId, toDate, name?.NameId)).ToArray();
            Assert.Equal(1, result.Count());
            Assert.Equal(case1.Id, result.First().CaseKey);
        }

        [Fact]
        public async Task ReturnsForSpecificSearchText()
        {
            var staffId = Fixture.Integer();
            var toDate = Fixture.Today();
            var f = new RecentCasesProviderFixture(Db);
            var case1 = new CaseBuilder {Irn = "Happy Man"}.Build().In(Db);
            var case2 = new CaseBuilder {Irn = "Sad Man"}.Build().In(Db);
            var case3 = new CaseBuilder {Irn = "Indifferent Man"}.Build().In(Db);
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-32), Case = case1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-100), Case = case1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-80), Case = case2}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-1), Case = case3}.BuildWithCase();

            var result = (await f.Subject.ForTimesheet(staffId, toDate, null, "Man")).ToArray();
            Assert.Equal(3, result.Count());
            Assert.Equal(case3.Id, result.First().CaseKey);
            Assert.Equal(case1.Id, result.Skip(1).First().CaseKey);
            Assert.Equal(case2.Id, result.Skip(2).First().CaseKey);
        }

        [Fact]
        public async Task ReturnsForSpecificNameAndSearchText()
        {
            var staffId = Fixture.Integer();
            var toDate = Fixture.Today();
            var f = new RecentCasesProviderFixture(Db);
            var case1 = new CaseBuilder {Irn = "Happy Man"}.Build().In(Db);
            var case2 = new CaseBuilder {Irn = "Sad Man"}.Build().In(Db);
            var case3 = new CaseBuilder {Irn = "Indifferent Man"}.Build().In(Db);
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-32), Case = case1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddHours(-100), Case = case1}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddHours(-80), Case = case2}.BuildWithCase();
            new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), FinishTime = toDate.AddDays(-1), Case = case3}.BuildWithCase();

            var name = case1.CaseNames.OrderBy(_ => _.Sequence).FirstOrDefault(_ => _.NameTypeId == "I");
            var result = (await f.Subject.ForTimesheet(staffId, toDate, name?.NameId, "Man")).ToArray();
            Assert.Equal(1, result.Count());
            Assert.Equal(case1.Id, result.First().CaseKey);

            result = (await f.Subject.ForTimesheet(staffId, toDate, name?.NameId, "Sad")).ToArray();
            Assert.Empty(result);
        }

        public class RecentCasesProviderFixture : IFixture<IRecentCasesProvider>
        {
            public RecentCasesProviderFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                DisplayFormattedName.For(Arg.Any<int[]>()).Returns(new Dictionary<int, NameFormatted>());
                Subject = new RecentCasesProvider(db, PreferredCultureResolver, DisplayFormattedName);
            }

            public IDisplayFormattedName DisplayFormattedName { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public IRecentCasesProvider Subject { get; }
        }
    }
}