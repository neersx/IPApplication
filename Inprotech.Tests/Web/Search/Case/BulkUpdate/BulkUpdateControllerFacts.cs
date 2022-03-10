using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.BulkCaseUpdates;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Cases.BulkUpdate;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.BulkUpdate
{
    public class BulkUpdateControllerFacts : FactBase
    {
        [Fact]
        public void VerifyGetViewDataWithNumberOfRecords()
        {
            var fixture = new BulkUpdateControllerFixture(Db);

            var firstTableCode = new TableCodeBuilder { TableCode = 11, TableType = (short)TableTypes.EntitySize }.Build().In(Db);
            new TableCodeBuilder { TableCode = 22, TableType = (short)TableTypes.EntitySize }.Build().In(Db);
            new TableCodeBuilder { TableCode = 33, TableType = (short)TableTypes.AccountType }.Build().In(Db);
            var textTypes = new[] { new TextTypeBuilder { Id = "AB" }.Build().In(Db), new TextTypeBuilder { Id = "XY" }.Build().In(Db) };
            fixture.UserFilteredTypes.TextTypes().Returns(textTypes);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainBulkCaseStatus).Returns(true);
            var result = fixture.Subject.Get();
            Assert.Equal(2, result.EntitySizes.Count);
            Assert.Equal(firstTableCode.Id, result.EntitySizes[0].Key);
            Assert.Equal(2, result.TextTypes.Count);
            Assert.Equal(textTypes[0].Id, result.TextTypes[0].Key);
            Assert.True(result.CanUpdateBulkStatus);
        }

        [Fact]
        public void VerifyGetViewDataWithEmptyResult()
        {
            var fixture = new BulkUpdateControllerFixture(Db);

            new TableCodeBuilder { TableCode = 11, TableType = (short)TableTypes.ActivityType }.Build().In(Db);
            new TableCodeBuilder { TableCode = 22, TableType = (short)TableTypes.AccountType }.Build().In(Db);
            var result = fixture.Subject.Get().EntitySizes;
            Assert.Empty(result);
        }

        [Fact]
        public void VerifyGetPolicingDataWithNumberOfRecords()
        {
            var fixture = new BulkUpdateControllerFixture(Db);

            fixture.SiteControlReader.Read<bool>(SiteControls.EnableRichTextFormatting).Returns(true);
            var textTypes = new[] { new TextTypeBuilder { Id = "AB" }.Build().In(Db), new TextTypeBuilder { Id = "XY" }.Build().In(Db) };
            fixture.UserFilteredTypes.TextTypes().Returns(textTypes);

            var result = fixture.Subject.GetPolicingViewData();
            Assert.Equal(2, result.TextTypes.Count);
            Assert.Equal(textTypes[0].Id, result.TextTypes[0].Key);
            Assert.True(result.AllowRichText);
        }

        [Fact]
        public void VerifyGetPolicingDataWithEmptyResult()
        {
            var fixture = new BulkUpdateControllerFixture(Db);
            var result = fixture.Subject.GetPolicingViewData().TextTypes;
            Assert.Empty(result);
        }

        [Fact]
        public void ShouldSendJobArgsToOrchestrator()
        {
            var f = new BulkUpdateControllerFixture(Db);

            var request = new BulkUpdateRequest
            {
                CaseIds = new[] { Fixture.Integer(), Fixture.Integer(), Fixture.Integer() },
                SaveData = new BulkUpdateData
                {
                    CaseFamily = new BulkSaveData { Key = Fixture.String("F") },
                    CaseOffice = new BulkSaveData { Key = Fixture.Integer().ToString() },
                    EntitySize = new BulkSaveData { ToRemove = true },
                    FileLocation = new BulkFileLocationUpdate { BayNumber = Fixture.String("BN"), FileLocation = Fixture.Integer(), MovedBy = Fixture.Integer(), WhenMoved = Fixture.Date() }
                },
                ReasonData = new BulkUpdateReasonData
                {
                    Notes = Fixture.String(),
                    TextType = Fixture.String("T")
                }
            };
            var processId = Fixture.Integer();

            f.BulkFieldUpdates.AddBackgroundProcess(BackgroundProcessSubType.NotSet).Returns(processId);

            var result = f.Subject.ApplyBulkUpdate(request);

            Assert.True(result.Status);
            f.BulkFieldUpdates.Received(1).AddBackgroundProcess(BackgroundProcessSubType.NotSet);

            f.ConfigureJob
             .Received(1)
             .AddBulkCaseUpdateJob(
                                  Arg.Is<BulkCaseUpdatesArgs>(_ => _.CaseIds == request.CaseIds
                                                                   && _.SaveData == request.SaveData
                                                                   && _.SaveData.FileLocation.FileLocation == request.SaveData.FileLocation.FileLocation
                                                                   && _.SaveData.FileLocation.BayNumber == request.SaveData.FileLocation.BayNumber
                                                                   && _.SaveData.FileLocation.MovedBy == request.SaveData.FileLocation.MovedBy
                                                                   && _.SaveData.FileLocation.WhenMoved == request.SaveData.FileLocation.WhenMoved
                                                                   && _.TextType == request.ReasonData.TextType
                                                                   && _.Notes == request.ReasonData.Notes
                                                                   && _.ProcessId == processId));
        }

        [Fact]
        public void VerifyApplyBulkUpdateWithoutCaseIds()
        {
            var f = new BulkUpdateControllerFixture(Db);
            var request = new BulkUpdateRequest
            {
                SaveData = new BulkUpdateData
                {
                    CaseFamily = new BulkSaveData { Key = Fixture.String("F") },
                    CaseOffice = new BulkSaveData { Key = Fixture.Integer().ToString() },
                    EntitySize = new BulkSaveData { ToRemove = true }
                }
            };
            var result = f.Subject.ApplyBulkUpdate(request);
            Assert.False(result.Status);
        }

        [Fact]
        public void VerifyApplyBulkUpdateForPolicing()
        {
            var f = new BulkUpdateControllerFixture(Db);
            var request = new BulkUpdateRequest
            {
                CaseIds = new[] { Fixture.Integer(), Fixture.Integer(), Fixture.Integer() },
                CaseAction = Fixture.String(),
                ReasonData = new BulkUpdateReasonData
                {
                    Notes = Fixture.String(),
                    TextType = Fixture.String("T")
                }
            };
           
            var processId = Fixture.Integer();
            f.BulkFieldUpdates.AddBackgroundProcess(BackgroundProcessSubType.Policing).Returns(processId);

            var result = f.Subject.ApplyBulkUpdate(request);
            Assert.True(result.Status);
            f.BulkFieldUpdates.Received(1).AddBackgroundProcess(BackgroundProcessSubType.Policing);
            f.ConfigureJob
             .Received(1)
             .AddBulkCaseUpdateJob(
                                   Arg.Is<BulkCaseUpdatesArgs>(_ => _.CaseIds == request.CaseIds
                                                                    && _.SaveData != null
                                                                    && _.CaseAction == request.CaseAction
                                                                    && _.TextType == request.ReasonData.TextType
                                                                    && _.Notes == request.ReasonData.Notes
                                                                    && _.ProcessId == processId));
        }

        [Fact]
        public async Task CheckRestrictedCasesForStatus()
        {
            var f = new BulkUpdateControllerFixture(Db);
            Assert.False(await f.Subject.HasRestrictedCasesForStatus(new RestrictedCasesStatusRequest()));
            var list = new List<int> {Fixture.Integer(), Fixture.Integer()};

            f.BulkCaseStatusUpdateHandler.GetRestrictedCasesForStatus(Arg.Any<int[]>(), Arg.Any<string>()).Returns(list);
            Assert.True(await f.Subject.HasRestrictedCasesForStatus(new RestrictedCasesStatusRequest {Cases = list, StatusCode = Fixture.String()}));
        }

        [Fact]
        public void CheckStatusPassword()
        {
            var f = new BulkUpdateControllerFixture(Db);
            Assert.False(f.Subject.CheckStatusPassword(string.Empty));

            var password = Fixture.String("pwd");
            f.SiteControlReader.Read<string>(SiteControls.ConfirmationPasswd).Returns(password);
            Assert.True(f.Subject.CheckStatusPassword(password));
        }
    }

    public class BulkUpdateControllerFixture : IFixture<BulkUpdateController>
    {
        public BulkUpdateControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            UserFilteredTypes = Substitute.For<IUserFilteredTypes>();
            BulkFieldUpdates = Substitute.For<IBulkFieldUpdates>();
            ConfigureJob = Substitute.For<IConfigureBulkCaseUpdatesJob>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            BulkCaseStatusUpdateHandler = Substitute.For<IBulkCaseStatusUpdateHandler>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new BulkUpdateController(db, PreferredCultureResolver, UserFilteredTypes, BulkFieldUpdates, ConfigureJob,
                                               TaskSecurityProvider, BulkCaseStatusUpdateHandler, SiteControlReader);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IUserFilteredTypes UserFilteredTypes { get; set; }
        public BulkUpdateController Subject { get; }
        public IBulkFieldUpdates BulkFieldUpdates { get; set; }
        public IConfigureBulkCaseUpdatesJob ConfigureJob { get; set; }
        public IBulkCaseStatusUpdateHandler BulkCaseStatusUpdateHandler { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
    }

}