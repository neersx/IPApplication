using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.BulkCaseUpdates;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.GlobalCaseChange;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.BulkCaseUpdates
{
    public class BulkCaseStatusUpdateHandlerFacts : FactBase
    {
        dynamic CreateMultiCases()
        {
            var firstCase = new CaseBuilder().Build().In(Db);
            var secondCase = new CaseBuilder().Build().In(Db);
            var thirdCase = new CaseBuilder().Build().In(Db);
            var caseList = new[] { firstCase.Id, secondCase.Id, thirdCase.Id };
            var status = new StatusBuilder().Build().In(Db);
            var cp1 = new CasePropertyBuilder {Case = firstCase, Status = status}.Build().In(Db);
            var cp2 = new CasePropertyBuilder {Case = secondCase, Status = status}.Build().In(Db);
            var status2 = new StatusBuilder().Build().In(Db);
            var process = new BackgroundProcess { ProcessType = BackgroundProcessType.GlobalCaseChange.ToString() }.In(Db);
            var gncResult1 = new GlobalCaseChangeResults {Id = process.Id, CaseId = firstCase.Id}.In(Db);
            var gncResult2 = new GlobalCaseChangeResults {Id = process.Id, CaseId = secondCase.Id}.In(Db);
            var gncResult3 = new GlobalCaseChangeResults {Id = process.Id, CaseId = thirdCase.Id}.In(Db);
            var gncResults = new List<GlobalCaseChangeResults> {gncResult1, gncResult2, gncResult3}.AsQueryable();

            return new
            {
                FirstCase = firstCase,
                SecondCase = secondCase,
                ThirdCase = thirdCase,
                CaseList = caseList,
                Status = status,
                cp1,
                cp2,
                status2,
                gncResults
            };
        }

        [Fact]
        public async Task ReturnsEmptyListWhenStatusPreventsWipAndNoCasesHasUnPostedTime()
        {
            var multiCases = CreateMultiCases();

            var restrictedCases = await new BulkCaseStatusUpdateHandlerFixture(Db).Subject.GetRestrictedCasesForStatus(multiCases.CaseList, multiCases.Status.Id.ToString());

            Assert.Null(restrictedCases);
        }

        [Fact]
        public async Task ReturnsCasesWhenStatusPreventsWipAndCaseHasUnPostedTime()
        {
            var multiCases = CreateMultiCases();
            multiCases.Status.PreventWip = true;
            new Diary { Case = multiCases.FirstCase, IsTimer = 0, TimeValue = 10 }.In(Db);

            var result = (IEnumerable<int>) await new BulkCaseStatusUpdateHandlerFixture(Db).Subject.GetRestrictedCasesForStatus(multiCases.CaseList, multiCases.Status.Id.ToString());
            var restrictedCases = result as int[] ?? result.ToArray();
            Assert.Equal(1, restrictedCases.Count());
            Assert.Equal(multiCases.FirstCase.Id, restrictedCases[0]);
        }

        [Fact]
        public async Task ReturnsCasesWhenStatusPreventsBillingAndCaseHasWip()
        {
            var multiCases = CreateMultiCases();
            multiCases.Status.PreventBilling = true;
            new Diary { Case = multiCases.FirstCase, IsTimer = 0, TimeValue = 10 }.In(Db);
            new WorkInProgress { Case = multiCases.SecondCase }.In(Db);

            var f = new BulkCaseStatusUpdateHandlerFixture(Db);
            var result = (IEnumerable<int>) await f.Subject.GetRestrictedCasesForStatus(multiCases.CaseList, multiCases.Status.Id.ToString());
            var restrictedCases = result as int[] ?? result.ToArray();
            Assert.Equal(2, restrictedCases.Count());
            Assert.Equal(multiCases.FirstCase.Id, restrictedCases[0]);
        }

        [Fact]
        public async Task RemovesCaseStatusFromSelectedCases()
        {
            var data = CreateMultiCases();
            var c1 = (Case) data.FirstCase;
            c1.StatusCode = data.Status.Id;
            c1.StopPayReason = Fixture.String();
            var c2 = (Case) data.SecondCase;
            c2.StatusCode = data.Status.Id;
            await Db.SaveChangesAsync();

            var f = new BulkCaseStatusUpdateHandlerFixture(Db);
            var updateData = new BulkUpdateData {CaseStatus = new BulkCaseStatusUpdate {ToRemove = true}};
            var casesToBeUpdated = new List<Case> {c1, c2 }.AsQueryable();
            await f.Subject.UpdateCaseStatusAsync(updateData, casesToBeUpdated, data.gncResults);
            Assert.Null(c1.StatusCode);
            Assert.Null(c2.StatusCode);
            Assert.NotNull(c1.StopPayReason);
        }

        [Fact]
        public async Task RemovesRenewalStatusFromSelectedCases()
        {
            var data = CreateMultiCases();
            var c1 = (Case) data.FirstCase;
            var c2 = (Case) data.SecondCase;
            var cp1 = new CasePropertyBuilder {Case = c1, Status = data.Status}.Build().In(Db);
            var cp2 = new CasePropertyBuilder {Case = c2, Status = data.Status}.Build().In(Db);

            var f = new BulkCaseStatusUpdateHandlerFixture(Db);
            var updateData = new BulkUpdateData {RenewalStatus = new BulkCaseStatusUpdate {ToRemove = true, IsRenewal = true}};
            var casesToBeUpdated = new List<Case> {c1, c2 }.AsQueryable();
            await f.Subject.UpdateCaseStatusAsync(updateData, casesToBeUpdated, data.gncResults);
            Assert.Null(cp1.RenewalStatusId);
            Assert.Null(cp2.RenewalStatusId);
        }

        [Fact]
        public async Task UpdateCaseStatusForSelectedCases()
        {
            var data = CreateMultiCases();
            var c1 = (Case) data.FirstCase;
            c1.StatusCode = data.Status.Id;
            var c2 = (Case) data.SecondCase;
            c2.StatusCode = data.Status.Id;
            c2.StopPayReason = Fixture.String();
            var s = new StatusBuilder().Build().In(Db);
            s.StopPayReason = Fixture.String("STP");
            new ValidStatusBuilder {CaseType = c1.Type, Country = c1.Country, PropertyType = c1.PropertyType, Status = s}.Build().In(Db);
            new SiteControlBuilder {SiteControlId = SiteControls.ConfirmationPasswd}.Build().In(Db);
            await Db.SaveChangesAsync();

            var f = new BulkCaseStatusUpdateHandlerFixture(Db);
            var updateData = new BulkUpdateData {CaseStatus = new BulkCaseStatusUpdate { StatusCode = s.Id.ToString()}};
            var casesToBeUpdated = new List<Case> {c1, c2 }.AsQueryable();
            await f.Subject.UpdateCaseStatusAsync(updateData, casesToBeUpdated, data.gncResults);
            Assert.Equal(s.Id, c1.StatusCode);
            Assert.Equal(data.Status.Id, c2.StatusCode);
            Assert.Equal(s.StopPayReason, c1.StopPayReason);
            Assert.NotEqual(s.StopPayReason, c2.StopPayReason);

            await f.BatchedSqlCommand.Received(1).ExecuteAsync(Arg.Any<string>(), Arg.Any<Dictionary<string, object>>());
        }

        [Fact]
        public async Task UpdateRenewalStatusForSelectedCases()
        {
            var data = CreateMultiCases();
            var c1 = (Case) data.FirstCase;
            var c2 = (Case) data.SecondCase;
            c2.StopPayReason = Fixture.String();
            var s = (Status) data.status2;
            s.StopPayReason = Fixture.String("STP");
            var anonymousCountry = new CountryBuilder() {Id = InprotechKaizen.Model.KnownValues.DefaultCountryCode}.Build().In(Db);
            new ValidStatusBuilder {CaseType = c1.Type, Country = c1.Country, PropertyType = c1.PropertyType, Status = s}.Build().In(Db);
            new ValidStatusBuilder {CaseType = c2.Type, Country = anonymousCountry, PropertyType = c2.PropertyType, Status = s}.Build().In(Db);
            new SiteControlBuilder {SiteControlId = SiteControls.ConfirmationPasswd}.Build().In(Db);
            await Db.SaveChangesAsync();

            var f = new BulkCaseStatusUpdateHandlerFixture(Db);
            var updateData = new BulkUpdateData {RenewalStatus = new BulkCaseStatusUpdate { IsRenewal = true, StatusCode = s.Id.ToString()}};
            var casesToBeUpdated = new List<Case> {c1, c2 }.AsQueryable();
            await f.Subject.UpdateCaseStatusAsync(updateData, casesToBeUpdated, data.gncResults);
            Assert.Equal(s.Id, data.cp1.RenewalStatusId);
            Assert.Equal(s.Id, data.cp2.RenewalStatusId);
            Assert.Equal(s.StopPayReason, c1.StopPayReason);
        }

        [Fact]
        public async Task AddPolicingRowForStatusChange()
        {
            var data = CreateMultiCases();
            var c1 = (Case) data.FirstCase;
            c1.StatusCode = data.Status.Id;
            var st1 = (Status)data.Status;
            st1.PoliceOtherActions = 0;
            var s = new StatusBuilder().Build().In(Db);
            s.PoliceOtherActions = 1;
            new ValidStatusBuilder {CaseType = c1.Type, Country = c1.Country, PropertyType = c1.PropertyType, Status = s}.Build().In(Db);
            var action1 = new ActionBuilder().Build().In(Db);
            action1.ActionType = 0;
            var oa1 = new OpenActionBuilder(Db) {Action = action1, Case = c1}.Build().In(Db);
            oa1.PoliceEvents = 1;
            new SiteControlBuilder {SiteControlId = SiteControls.ConfirmationPasswd}.Build().In(Db);
            await Db.SaveChangesAsync();

            var f = new BulkCaseStatusUpdateHandlerFixture(Db);
            var updateData = new BulkUpdateData {CaseStatus = new BulkCaseStatusUpdate { StatusCode = s.Id.ToString()}};
            var casesToBeUpdated = new List<Case> {c1 }.AsQueryable();
            await f.Subject.UpdateCaseStatusAsync(updateData, casesToBeUpdated, data.gncResults);
            Assert.Equal(s.Id, c1.StatusCode);
            Assert.True(Db.Set<PolicingRequest>().Any( _ => _.CaseId == c1.Id && _.Action == oa1.ActionId && _.TypeOfRequest == 1 && _.Name.Contains("Status")));
        }

        [Fact]
        public async Task AddPolicingRowForRenewalStatusChange()
        {
            var data = CreateMultiCases();
            var c1 = (Case) data.FirstCase;
            var st1 = (Status)data.Status;
            st1.PoliceOtherActions = 0;
            var s = (Status) data.status2;
            s.PoliceOtherActions = 1;
            new ValidStatusBuilder {CaseType = c1.Type, Country = c1.Country, PropertyType = c1.PropertyType, Status = s}.Build().In(Db);
            var action1 = new ActionBuilder().Build().In(Db);
            action1.ActionType = 0;
            var oa1 = new OpenActionBuilder(Db) {Action = action1, Case = c1}.Build().In(Db);
            oa1.PoliceEvents = 1;
            new SiteControlBuilder {SiteControlId = SiteControls.ConfirmationPasswd}.Build().In(Db);
            await Db.SaveChangesAsync();

            var f = new BulkCaseStatusUpdateHandlerFixture(Db);
            var updateData = new BulkUpdateData {RenewalStatus = new BulkCaseStatusUpdate { IsRenewal = true, StatusCode = s.Id.ToString()}};
            var casesToBeUpdated = new List<Case> {c1 }.AsQueryable();
            await f.Subject.UpdateCaseStatusAsync(updateData, casesToBeUpdated, data.gncResults);
            Assert.Equal(s.Id, data.cp1.RenewalStatusId);
            Assert.True(Db.Set<PolicingRequest>().Any( _ => _.CaseId == c1.Id && _.Action == oa1.ActionId && _.TypeOfRequest == 1 && _.Name.Contains("Status")));
        }

        [Fact]
        public async Task DoNotUpdateCaseStatusIfPasswordNotMatched()
        {
            var data = CreateMultiCases();
            var c1 = (Case) data.FirstCase;
            var s = new StatusBuilder().Build().In(Db);
            s.ConfirmationRequiredFlag = 1;
            await Db.SaveChangesAsync();

            var f = new BulkCaseStatusUpdateHandlerFixture(Db);
            f.SiteControlReader.Read<string>(SiteControls.ConfirmationPasswd).Returns(Fixture.String());
            var updateData = new BulkUpdateData {CaseStatus = new BulkCaseStatusUpdate { StatusCode = s.Id.ToString(), Password = Fixture.String() }};
            var casesToBeUpdated = new List<Case> {c1 }.AsQueryable();

            await f.Subject.UpdateCaseStatusAsync(updateData, casesToBeUpdated, data.gncResults);
        }
    }

    public class BulkCaseStatusUpdateHandlerFixture : IFixture<BulkCaseStatusUpdateHandler>
    {
        public ISecurityContext SecurityContext { get; set; }

        public Func<DateTime> DateFunc { get; set; }

        public IBatchedSqlCommand BatchedSqlCommand { get; set; }

        public ISiteControlReader SiteControlReader { get; set; }

        public BulkCaseStatusUpdateHandler Subject { get; set; }

        public BulkCaseStatusUpdateHandlerFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            BatchedSqlCommand = Substitute.For<IBatchedSqlCommand>();
            DateFunc = Substitute.For<Func<DateTime>>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new BulkCaseStatusUpdateHandler(db, SecurityContext, DateFunc, BatchedSqlCommand, SiteControlReader);
            DateFunc().Returns(Fixture.Today());
            SecurityContext.User.Returns(new User { Name = new NameBuilder(db).Build() });
        }
    }
}
