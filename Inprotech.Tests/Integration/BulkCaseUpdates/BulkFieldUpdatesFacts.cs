using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.BulkCaseUpdates;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.GlobalCaseChange;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.BulkCaseUpdates
{
    public class BulkFieldUpdatesFacts : FactBase
    {
        dynamic SetData()
        {
            var c1 = new CaseBuilder().Build().In(Db);
            var c2 = new CaseBuilder().Build().In(Db);
            var c3 = new CaseBuilder().Build().In(Db);
            var process = new BackgroundProcess { ProcessType = BackgroundProcessType.GlobalCaseChange.ToString() }.In(Db);
            var office = new OfficeBuilder().Build().In(Db);
            var family = new Family(Fixture.String(), Fixture.String()).In(Db);
            var entitySize = new TableCodeBuilder() { TableType = (int)TableTypes.EntitySize }.Build().In(Db);
            var profitCenter = new ProfitCentreBuilder().Build().In(Db);
            var typeOfMark = new TableCodeBuilder { TableType = (int)TableTypes.TypeOfMark }.Build().In(Db);

            return new
            {
                c1,
                c2,
                c3,
                ProcessId = process.Id,
                office,
                family,
                entitySize,
                profitCenter,
                typeOfMark
            };
        }

        [Fact]
        public void AddsBackgroundProcessForBulkUpdates()
        {
            var f = new BulkFieldUpdatesFixture(Db);
            var processId = f.Subject.AddBackgroundProcess(BackgroundProcessSubType.NotSet);

            var process = Db.Set<BackgroundProcess>().Last(_ => _.IdentityId == f.SecurityContext.User.Id);
            Assert.Equal(processId, process.Id);
            Assert.Equal(BackgroundProcessType.GlobalCaseChange.ToString(), process.ProcessType);
            Assert.Equal((int)StatusType.Started, process.Status);
            Assert.Equal(Fixture.Today(), process.StatusDate);
        }

        [Fact]
        public void AddsBackgroundProcessForBulkPolicing()
        {
            var f = new BulkFieldUpdatesFixture(Db);
            var processId = f.Subject.AddBackgroundProcess(BackgroundProcessSubType.Policing);

            var process = Db.Set<BackgroundProcess>().Last(_ => _.IdentityId == f.SecurityContext.User.Id);
            Assert.Equal(processId, process.Id);
            Assert.Equal(BackgroundProcessType.GlobalCaseChange.ToString(), process.ProcessType);
            Assert.Equal(BackgroundProcessSubType.Policing.ToString(), process.ProcessSubType);
        }

        [Fact]
        public async Task ReturnsIfBackgroundProcessNotFound()
        {
            var f = new BulkFieldUpdatesFixture(Db);
            await f.Subject.BulkUpdateCases(new BulkCaseUpdatesArgs()
            {
                ProcessId = Fixture.Integer()
            });
            await f.BulkFieldUpdateHandler.Received(0).GetCases(Arg.Any<int[]>());
        }

        [Fact]
        public async Task SuccessfullyApplyBulkUpdates()
        {
            var f = new BulkFieldUpdatesFixture(Db);
            var data = SetData();
            var caseIds = new[] { (int)data.c1.Id, (int)data.c2.Id, (int)data.c3.Id };
            var textType = new TextTypeBuilder().Build().In(Db);
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = caseIds,
                SaveData = new BulkUpdateData
                {
                    CaseFamily = new BulkSaveData { Key = data.family.Id },
                    CaseOffice = new BulkSaveData { Key = data.office.Id.ToString() },
                    EntitySize = new BulkSaveData { Key = data.entitySize.Id.ToString() },
                    ProfitCentre = new BulkSaveData { Key = data.profitCenter.Id.ToString() },
                    PurchaseOrder = new BulkSaveData { Key = Fixture.String("PO") },
                    TitleMark = new BulkSaveData { Key = Fixture.String("Title") },
                    TypeOfMark = new BulkSaveData { Key = data.typeOfMark.Id.ToString() }
                },
                TextType = textType.Id,
                Notes = Fixture.String("Notes")
            };
          
            f.BulkFieldUpdateHandler.GetCases(Arg.Any<int[]>()).Returns( new BulkUpdateCases
            {
                AuthorizedCases = new [] {(int)data.c1.Id, (int)data.c2.Id},
                UnauthorizedCases = new []{(int)data.c3.Id}
            });
          
            f.BulkFieldUpdateHandler.Update(Arg.Any<IQueryable<Case>>(), request).Returns( new BulkUpdateResult
            {
               ProcessId = data.ProcessId,
               HasOfficeUpdated = true,
               HasEntitySizeUpdated = true,
               HasTitleUpdated = true,
               HasPurchaseOrderUpdated = true,
               HasTypeOfMarkUpdated = true,
               HasProfitCentreUpdated = true,
               HasFamilyUpdated = true
            });

            await f.Subject.BulkUpdateCases(request);

            var process = Db.Set<BackgroundProcess>().FirstOrDefault(_ => _.Id == request.ProcessId);
            Assert.Equal((int)StatusType.Completed, process?.Status);
            await f.SqlCommand.Received(2).ExecuteAsync(Arg.Any<string>(), Arg.Any<Dictionary<string, object>>());
        }
        
        [Fact]
        public async Task SuccessfullyRollbackOnException()
        {
            var f = new BulkFieldUpdatesFixture(Db);
            var data = SetData();
            var caseIds = new[] { (int)data.c1.Id, (int)data.c2.Id, (int)data.c3.Id };
            var textType = new TextTypeBuilder().Build().In(Db);
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = caseIds,
                SaveData = new BulkUpdateData
                {
                    CaseFamily = new BulkSaveData { Key = data.family.Id },
                    CaseOffice = new BulkSaveData { Key = data.office.Id.ToString() },
                    EntitySize = new BulkSaveData { Key = data.entitySize.Id.ToString() },
                    ProfitCentre = new BulkSaveData { Key = data.profitCenter.Id.ToString() },
                    PurchaseOrder = new BulkSaveData { Key = Fixture.String("PO") },
                    TitleMark = new BulkSaveData { Key = Fixture.String("Title") },
                    TypeOfMark = new BulkSaveData { Key = data.typeOfMark.Id.ToString() }
                },
                TextType = textType.Id,
                Notes = Fixture.String("Notes")
            };
          
            f.BulkFieldUpdateHandler.GetCases(Arg.Any<int[]>()).Returns( new BulkUpdateCases
            {
                AuthorizedCases = new [] {(int)data.c1.Id, (int)data.c2.Id},
                UnauthorizedCases = new []{(int)data.c3.Id}
            });

            f.BulkFieldUpdateHandler.Update(Arg.Any<IQueryable<Case>>(), Arg.Any<BulkCaseUpdatesArgs>())
             .Returns<BulkUpdateResult>(_ => throw new Exception("intentionally raised"));

            await Assert.ThrowsAnyAsync<Exception>(async () => await f.Subject.BulkUpdateCases(request));

            var process = Db.Set<BackgroundProcess>().FirstOrDefault(_ => _.Id == request.ProcessId);
            var results = Db.Set<GlobalCaseChangeResults>().Where(_ => _.Id == request.ProcessId).ToArray();

            Assert.Equal((int)StatusType.Error, process?.Status);
            Assert.Equal(0, results.Count());
        }
    }

    public class BulkFieldUpdatesFixture : IFixture<BulkFieldUpdates>
    {
        public ISecurityContext SecurityContext { get; set; }
        public IBulkFieldUpdateHandler BulkFieldUpdateHandler { get; set; }
        public Func<DateTime> DateFunc { get; set; }
        public BulkFieldUpdates Subject { get; set; }
        public IBatchedSqlCommand SqlCommand { get; set; }

        public BulkFieldUpdatesFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            BulkFieldUpdateHandler = Substitute.For<IBulkFieldUpdateHandler>();
            DateFunc = Substitute.For<Func<DateTime>>();
            SqlCommand = Substitute.For<IBatchedSqlCommand>();
            Subject = new BulkFieldUpdates(db, SecurityContext, BulkFieldUpdateHandler, DateFunc, SqlCommand);
            DateFunc().Returns(Fixture.Today());
            SecurityContext.User.Returns(new User { Name = new NameBuilder(db) { NameCode = "GG" }.Build() });
        }
    }
}
