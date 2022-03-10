using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.BulkCaseUpdates;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.GlobalCaseChange;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Integration.BulkCaseUpdates
{
    public class BulkPolicingHandlerFacts : FactBase
    {
        dynamic SetData()
        {
            var c1 = new CaseBuilder().Build().In(Db);
            var c2 = new CaseBuilder().Build().In(Db);
            var c3 = new CaseBuilder().Build().In(Db);
            var process = new BackgroundProcess { ProcessType = BackgroundProcessType.GlobalCaseChange.ToString() }.In(Db);
            var action = new ActionBuilder().Build().In(Db);
            var gncResults1 = new GlobalCaseChangeResults {Case = c1, BackgroundProcess = process, CaseId = c1.Id, Id = process.Id}.In(Db);
            var gncResults2 = new GlobalCaseChangeResults {Case = c2, BackgroundProcess = process, CaseId = c2.Id, Id = process.Id}.In(Db);
            var gncResults3 = new GlobalCaseChangeResults {Case = c3, BackgroundProcess = process, CaseId = c3.Id, Id = process.Id}.In(Db);
            var gncResults = new [] {gncResults1, gncResults2, gncResults3};

            return new
            {
                c1,
                c2,
                c3,
                ProcessId = process.Id,
                action,
                gncResults
            };
        }

        [Fact]
        public async Task ShouldNotCallBulkPolicingIfActionNotPresent()
        {
            var f = new BulkPolicingHandlerFixture(Db);
            var data = SetData();
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = new[] { (int)data.c1.Id, (int)data.c2.Id, (int)data.c3.Id },
                SaveData = new BulkUpdateData()
            };
            var casesToBeUpdated = Db.Set<Case>().Where(_ => request.CaseIds.Contains(_.Id));
            var gncResults = Db.Set<GlobalCaseChangeResults>().Where(_ => _.Id == request.ProcessId);
            await f.Subject.BulkPolicingAsync(request, casesToBeUpdated, gncResults);
            await f.BatchedSqlCommand.Received(0).ExecuteAsync(Arg.Any<string>(), Arg.Any<Dictionary<string, object>>());
        }

        [Fact]
        public async Task ShouldThrowExceptionIfActionNotFound()
        {
            var f = new BulkPolicingHandlerFixture(Db);
            var data = SetData();
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = new[] { (int)data.c1.Id, (int)data.c2.Id, (int)data.c3.Id },
                SaveData = new BulkUpdateData(),
                CaseAction = Fixture.String("AC")
            };
            var casesToBeUpdated = Db.Set<Case>().Where(_ => request.CaseIds.Contains(_.Id));
            var gncResults = Db.Set<GlobalCaseChangeResults>().Where(_ => _.Id == request.ProcessId);
            var exception = await Assert.ThrowsAsync<ArgumentException>(async () => await f.Subject.BulkPolicingAsync(request, casesToBeUpdated, gncResults));

            Assert.IsType<ArgumentException>(exception);
            Assert.Equal("Case Action not found", exception.Message);
        }

        [Fact]
        public async Task ShouldAddBatchPolicing()
        {
            var f = new BulkPolicingHandlerFixture(Db);
            var data = SetData();
            var action = (Action)data.action;
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = new[] { (int)data.c1.Id, (int)data.c2.Id, (int)data.c3.Id },
                SaveData = new BulkUpdateData(),
                CaseAction = action.Code
            };
            var batchNo = Fixture.Short();
            f.PolicingEngine.CreateBatch().Returns(batchNo);
            var casesToBeUpdated = Db.Set<Case>().Where(_ => request.CaseIds.Contains(_.Id));
            var gncResults = Db.Set<GlobalCaseChangeResults>().Where(_ => _.Id == request.ProcessId);
            await f.Subject.BulkPolicingAsync(request, casesToBeUpdated, gncResults);

            Assert.True(gncResults.First().IsPoliced);
            Assert.True(gncResults.Last().IsPoliced);

            f.PolicingEngine.Received(1).CreateBatch();
            await f.BatchedSqlCommand.Received(1).ExecuteAsync(Arg.Any<string>(), Arg.Any<Dictionary<string, object>>());
            await f.PolicingEngine.Received(1).PoliceWithoutTransaction(batchNo);
            
        }
    }

    public class BulkPolicingHandlerFixture : IFixture<BulkPolicingHandler>
    {
        public BulkPolicingHandler Subject { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public IBatchedSqlCommand BatchedSqlCommand { get; set; }
        public IPolicingEngine PolicingEngine { get; set; }

        public BulkPolicingHandlerFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            BatchedSqlCommand = Substitute.For<IBatchedSqlCommand>();
            PolicingEngine = Substitute.For<IPolicingEngine>();
            Subject = new BulkPolicingHandler(db, SecurityContext, BatchedSqlCommand, PolicingEngine);
            SecurityContext.User.Returns(new User { Name = new NameBuilder(db) { NameCode = "GG" }.Build() });
        }
    }
}
