using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.Security;
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
    public class BulkFieldUpdateHandlerFacts : FactBase
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
            new GlobalCaseChangeResults {Id = process.Id, CaseId = c1.Id}.In(Db);

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
        public async Task ShouldReturnsAuthorizedAndUnAuthorizedCaseLists()
        {
            var f = new BulkFieldUpdateHandlerFixture(Db);
            var data = SetData();
            var caseIds = new[] { (int)data.c1.Id, (int)data.c2.Id, (int)data.c3.Id };
            f.CaseAuthorization.UpdatableCases(caseIds).Returns(new List<int> {caseIds[0], caseIds[1]});
            var result = await f.Subject.GetCases(caseIds);

            Assert.Equal(2, result.AuthorizedCases.Length);
            Assert.Equal(1, result.UnauthorizedCases.Length);
        }

        [Fact]
        public async Task ShouldSuccessfullyExecuteBulkFieldUpdate()
        {
            var f = new BulkFieldUpdateHandlerFixture(Db);
            var data = SetData();
            var cases = new Case[] { data.c1, data.c2, data.c3 };
            var textType = new TextTypeBuilder().Build().In(Db);
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = new[] { (int)data.c1.Id, (int)data.c2.Id, (int)data.c3.Id },
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

            var result = await f.Subject.Update(cases.AsQueryable(), request);

            Assert.NotNull(result);
            Assert.True(result.HasEntitySizeUpdated);
            Assert.True(result.HasFamilyUpdated);
            Assert.True(result.HasOfficeUpdated);
            Assert.True(result.HasProfitCentreUpdated);
            Assert.True(result.HasPurchaseOrderUpdated);
            Assert.True(result.HasTitleUpdated);
            Assert.True(result.HasTypeOfMarkUpdated);
            Assert.Equal(data.ProcessId, result.ProcessId);

            var @caseId = (int)data.c1.Id;
            var updatedCase = Db.Set<Case>().Single(_ => _.Id == @caseId);
            var c1 = (Case)data.c1;
            Assert.Equal(c1.FamilyId, updatedCase.FamilyId);
            Assert.Equal(c1.OfficeId, updatedCase.OfficeId);
            Assert.Equal(c1.EntitySizeId, updatedCase.EntitySizeId);
            Assert.Equal(c1.TypeOfMarkId, updatedCase.TypeOfMarkId);
            Assert.Equal(c1.ProfitCentreCode, updatedCase.ProfitCentreCode);
            Assert.Contains("PO", updatedCase.PurchaseOrderNo);
            Assert.Contains("Title", updatedCase.Title);

            var gncResults = Db.Set<GlobalCaseChangeResults>().Single(_ => _.CaseId == @caseId && _.Id == request.ProcessId);
            Assert.True(gncResults.FamilyUpdated);
            Assert.True(gncResults.OfficeUpdated);
            Assert.True(gncResults.EntitySizeUpdated);
            Assert.True(gncResults.TypeOfMarkUpdated);
            Assert.True(gncResults.ProfitCentreCodeUpdated);
            Assert.True(gncResults.PurchaseOrderNoUpdated);
            Assert.True(gncResults.TitleUpdated);

            await f.BulkPolicingHandler.Received(0).BulkPolicingAsync(request, Arg.Any<IQueryable<Case>>(), Arg.Any<IQueryable<GlobalCaseChangeResults>>());
            await f.BulkCaseTextUpdateHandler.Received(1).UpdateTextTypeAsync(request, Arg.Any<IQueryable<Case>>(), Arg.Any<IQueryable<GlobalCaseChangeResults>>());
        }

        [Fact]
        public async Task ShouldSuccessfullyExecuteBulkPolicingUpdate()
        {
            var f = new BulkFieldUpdateHandlerFixture(Db);
            var data = SetData();
            var cases = new Case[] { data.c1, data.c2, data.c3 };
            var textType = new TextTypeBuilder().Build().In(Db);
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = new[] { (int)data.c1.Id, (int)data.c2.Id, (int)data.c3.Id },
                SaveData = new BulkUpdateData(),
                CaseAction = Fixture.String(),
                TextType = textType.Id,
                Notes = Fixture.String("Notes")
            };

            var result = await f.Subject.Update(cases.AsQueryable(), request);

            Assert.NotNull(result);
            Assert.False(result.HasEntitySizeUpdated);
            Assert.Equal(data.ProcessId, result.ProcessId);
            await f.BulkPolicingHandler.Received(1).BulkPolicingAsync(request, Arg.Any<IQueryable<Case>>(), Arg.Any<IQueryable<GlobalCaseChangeResults>>());
            await f.BulkCaseTextUpdateHandler.Received(1).UpdateTextTypeAsync(request, Arg.Any<IQueryable<Case>>(), Arg.Any<IQueryable<GlobalCaseChangeResults>>());
        }
    }

    public class BulkFieldUpdateHandlerFixture : IFixture<BulkFieldUpdateHandler>
    {
        public ISecurityContext SecurityContext { get; set; }

        public IBulkCaseTextUpdateHandler BulkCaseTextUpdateHandler { get; set; }
        public IBulkCaseStatusUpdateHandler BulkCaseStatusUpdateHandler { get; set; }

        public IBulkCaseNameReferenceUpdateHandler BulkCaseNameReferenceUpdateHandler { get; set; }

        public IBulkFileLocationUpdateHandler BulkFileLocationUpdateHandler { get; set; }

        public IBulkPolicingHandler BulkPolicingHandler { get; set; }

        public ICaseAuthorization CaseAuthorization { get; set; }

        public Func<DateTime> DateFunc { get; set; }

        public BulkFieldUpdateHandler Subject { get; set; }

        public BulkFieldUpdateHandlerFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            BulkCaseNameReferenceUpdateHandler = Substitute.For<IBulkCaseNameReferenceUpdateHandler>();
            BulkCaseTextUpdateHandler = Substitute.For<IBulkCaseTextUpdateHandler>();
            BulkFileLocationUpdateHandler = Substitute.For<IBulkFileLocationUpdateHandler>();
            BulkCaseStatusUpdateHandler = Substitute.For<IBulkCaseStatusUpdateHandler>();
            BulkPolicingHandler = Substitute.For<IBulkPolicingHandler>();
            CaseAuthorization = Substitute.For<ICaseAuthorization>();
            DateFunc = Substitute.For<Func<DateTime>>();
            Subject = new BulkFieldUpdateHandler(db, SecurityContext, CaseAuthorization, DateFunc, BulkCaseTextUpdateHandler, BulkCaseNameReferenceUpdateHandler, BulkFileLocationUpdateHandler, BulkCaseStatusUpdateHandler, BulkPolicingHandler);
            DateFunc().Returns(Fixture.Today());
            SecurityContext.User.Returns(new User { Name = new NameBuilder(db) { NameCode = "GG" }.Build() });
        }
    }
}
