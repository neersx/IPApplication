using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class StatusMaintenanceControllerFacts
    {
        public class GetSupportDataMethod : FactBase
        {
            dynamic CreateSupportData()
            {
                var stopPayReasons = new List<StopPayReason>
                {
                    new StopPayReason {Id = 6501, Name = "Abandoned", UserCode = "A"},
                    new StopPayReason {Id = 6502, Name = "Paid through other channels", UserCode = "C"},
                    new StopPayReason {Id = 6503, Name = "Unspecified", UserCode = "U"}
                }.AsEnumerable();

                var permissions = new
                {
                    CanUpdate = true,
                    CanDelete = true,
                    CanCreate = false,
                    CanMaintainValidCombination = true
                };

                return new
                {
                    stopPayReasons,
                    permissions
                };
            }

            [Fact]
            public void ReturnsSupportData()
            {
                var data = CreateSupportData();

                var f = new StatusMaintenanceControllerFixture(Db);

                f.StatusSupport.StopPayReasons().Returns((IEnumerable<StopPayReason>) data.stopPayReasons);
                f.StatusSupport.Permissions().Returns(data.permissions);

                var result = f.Subject.GetSupportData();

                var stopPayReasons = (IEnumerable<StopPayReason>) result.stopPayReasons;
                var permissions = result.permissions;

                Assert.Equal(3, stopPayReasons.Count());
                Assert.True(permissions.CanUpdate);
                Assert.False(permissions.CanCreate);
                Assert.True(permissions.CanMaintainValidCombination);
            }
        }

        public class SearchMethod : FactBase
        {
            StatusSearchOptions CreateOptions(string text)
            {
                return new StatusSearchOptions
                {
                    Text = text
                };
            }

            [Fact]
            public void ReturnsNoOfCasePropertiesForStatuses()
            {
                var options = CreateOptions(string.Empty);
                options.IsRenewal = true;

                var f = new StatusMaintenanceControllerFixture(Db);
                var statuses = f.CreateStatusList();
                var renewalStatus1 = (Status) statuses.renewalStatus1;
                var renewalStatus2 = (Status) statuses.renewalStatus2;

                var firstCase = new CaseBuilder {Status = renewalStatus1}.Build().In(Db);
                var secondCase = new CaseBuilder {Status = renewalStatus2}.Build().In(Db);

                new CaseProperty(firstCase, new ApplicationBasis(Fixture.String(), Fixture.String()), renewalStatus1).In(Db);
                new CaseProperty(firstCase, new ApplicationBasis(Fixture.String(), Fixture.String()), renewalStatus1).In(Db);
                new CaseProperty(secondCase, new ApplicationBasis(Fixture.String(), Fixture.String()), renewalStatus1).In(Db);
                new CaseProperty(secondCase, new ApplicationBasis(Fixture.String(), Fixture.String()), renewalStatus2).In(Db);

                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var searchResults = ((IEnumerable<dynamic>) f.Subject.Search(options)).ToArray();

                Assert.Equal(3, searchResults.Single(_ => _.Id == statuses.renewalStatus1.Id).NoOfCases);
                Assert.Equal(1, searchResults.Single(_ => _.Id == statuses.renewalStatus2.Id).NoOfCases);
            }

            [Fact]
            public void ReturnsNoOfCasesForStatuses()
            {
                var options = CreateOptions(string.Empty);

                var f = new StatusMaintenanceControllerFixture(Db);
                var statuses = f.CreateStatusList();
                var caseStatus1 = (Status) statuses.caseStatus1;
                var caseStatus2 = (Status) statuses.caseStatus2;

                new CaseBuilder {Status = caseStatus1}.Build().In(Db);
                new CaseBuilder {Status = caseStatus1}.Build().In(Db);
                new CaseBuilder {Status = caseStatus2}.Build().In(Db);

                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var searchResults = ((IEnumerable<dynamic>) f.Subject.Search(options)).ToArray();

                Assert.Equal(2, searchResults.Single(_ => _.Id == statuses.caseStatus1.Id).NoOfCases);
                Assert.Equal(1, searchResults.Single(_ => _.Id == statuses.caseStatus2.Id).NoOfCases);
            }

            [Fact]
            public void ReturnsStatusSearchingByDescription()
            {
                var options = CreateOptions("CPA");
                options.IsRenewal = true;

                var f = new StatusMaintenanceControllerFixture(Db);
                var statuses = f.CreateStatusList();
                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var searchResults = (IEnumerable<dynamic>) f.Subject.Search(options);

                Assert.NotNull(searchResults.SingleOrDefault(_ => _.Id == statuses.renewalStatus1.Id));
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnMatchingStatusForGivenStatusCode()
            {
                var f = new StatusMaintenanceControllerFixture(Db);
                var statuses = f.CreateStatusList();
                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var status = f.Subject.Get(statuses.caseStatus1.Id);

                Assert.Equal(statuses.caseStatus1.Id, status.Id);
            }
        }

        public class SaveMethod : FactBase
        {
            SaveStatusModel PrepareSave()
            {
                return new SaveStatusModel
                {
                    Name = Fixture.String("InternalDesc"),
                    ExternalName = Fixture.String("ExternalDesc"),
                    IsDead = false,
                    IsRegistered = false,
                    IsPending = true,
                    IsRenewal = false,
                    PoliceRenewals = false,
                    PoliceExam = true,
                    PoliceOtherActions = true,
                    LettersAllowed = true,
                    ChargesAllowed = true,
                    RemindersAllowed = true,
                    ConfirmationRequired = false,
                    StopPayReason = new StopPayReason {Id = Fixture.Integer(), Name = "Abandoned", UserCode = "B"},
                    PreventWip = true,
                    PreventBilling = false,
                    PreventPrepayment = true,
                    PriorArtFlag = true
                };
            }

            [Fact]
            public void ExternalDescIsCopiedFromInternalDescWhenNotEntered()
            {
                var f = new StatusMaintenanceControllerFixture(Db);
                f.CreateStatusList();
                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var lastInternalCode = Fixture.Short();
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Status).Returns(lastInternalCode);

                var statusSaveModel = PrepareSave();
                statusSaveModel.ExternalName = null;

                var response = f.Subject.Save(statusSaveModel);
                var status = Db.Set<Status>().Single(_ => _.Id == lastInternalCode);

                Assert.Equal(response.Result, "success");
                Assert.Equal(response.UpdatedId, lastInternalCode);
                Assert.Equal(status.Name, status.ExternalName);
            }

            [Fact]
            public void ReturnsErrorWhenAddedInternalDescriptionAlreadyExists()
            {
                var f = new StatusMaintenanceControllerFixture(Db);
                f.CreateStatusList();
                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var lastInternalCode = Fixture.Short();
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Status).Returns(lastInternalCode);

                var statusSaveModel = PrepareSave();
                statusSaveModel.Name = "CPA to be notified";
                statusSaveModel.ExternalName = "CPA to be notified";
                statusSaveModel.IsRenewal = true;
                statusSaveModel.StatusType = StatusType.Renewal;

                var status = f.Subject.Save(statusSaveModel);
                Assert.Equal(status.Errors[0].Message, "field.errors.notunique");
            }

            [Fact]
            public void ReturnsSuccessAndUpdatedId()
            {
                var f = new StatusMaintenanceControllerFixture(Db);
                f.CreateStatusList();
                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var lastInternalCode = Fixture.Short();
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Status).Returns(lastInternalCode);

                var status = f.Subject.Save(PrepareSave());

                Assert.Equal(status.Result, "success");
                Assert.Equal(status.UpdatedId, lastInternalCode);
                Assert.Equal(5, Db.Set<Status>().Count());
            }

            [Fact]
            public void SetCorrectValuesInDatabaseForStatus()
            {
                var f = new StatusMaintenanceControllerFixture(Db);
                f.CreateStatusList();
                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var lastInternalCode = Fixture.Short();
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Status).Returns(lastInternalCode);

                var saveStatusModel = PrepareSave();
                f.Subject.Save(saveStatusModel);

                var savedStatus = Db.Set<Status>().First(st => st.Id == lastInternalCode);

                Assert.Equal(saveStatusModel.Name, savedStatus.Name);
                Assert.Equal(saveStatusModel.ExternalName, savedStatus.ExternalName);
                Assert.True(savedStatus.LiveFlag.ToBoolean());
                Assert.False(savedStatus.RegisteredFlag.ToBoolean());
                Assert.Equal(saveStatusModel.PoliceRenewals, savedStatus.PoliceRenewals.ToBoolean());
                Assert.Equal(saveStatusModel.PoliceExam, savedStatus.PoliceExam.ToBoolean());
                Assert.Equal(saveStatusModel.PoliceOtherActions, savedStatus.PoliceOtherActions.ToBoolean());
                Assert.Equal(saveStatusModel.LettersAllowed, savedStatus.LettersAllowed.ToBoolean());
                Assert.Equal(saveStatusModel.ChargesAllowed, savedStatus.ChargesAllowed.ToBoolean());
                Assert.Equal(saveStatusModel.RemindersAllowed, savedStatus.RemindersAllowed.ToBoolean());
                Assert.Equal(saveStatusModel.ConfirmationRequired, savedStatus.IsConfirmationRequired);
                Assert.Equal(saveStatusModel.PreventWip, savedStatus.PreventWip);
                Assert.Equal(saveStatusModel.PreventBilling, savedStatus.PreventBilling);
                Assert.Equal(saveStatusModel.PreventPrepayment, savedStatus.PreventPrepayment);
                Assert.Equal(saveStatusModel.PriorArtFlag, savedStatus.PriorArtFlag);
                Assert.Equal(saveStatusModel.StopPayReason.UserCode, savedStatus.StopPayReason);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPasses()
            {
                var f = new StatusMaintenanceControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveModel", exception.Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            SaveStatusModel PrepareSave(Status status)
            {
                return StatusTranslator.ConvertToSaveStatusModel(status, null);
            }

            [Fact]
            public void ReturnsErrorWhenUpdatedInternalDescriptionAlreadyExists()
            {
                var f = new StatusMaintenanceControllerFixture(Db);
                var statuses = f.CreateStatusList();
                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var statusSaveModel = PrepareSave(statuses.caseStatus1);
                statusSaveModel.Name = "CPA to be notified";
                statusSaveModel.ExternalName = "CPA to be notified";
                statusSaveModel.IsRenewal = true;
                statusSaveModel.StatusType = StatusType.Renewal;

                var id = (short) statuses.caseStatus1.Id;
                var status = f.Subject.Update(id, statusSaveModel);

                Assert.Equal(status.Errors[0].Message, "field.errors.notunique");
            }

            [Fact]
            public void ReturnsSuccessAndUpdatedId()
            {
                var f = new StatusMaintenanceControllerFixture(Db);
                var statuses = f.CreateStatusList();
                f.StatusSupport.StopPayReasonFor(Arg.Any<string>()).Returns(new StopPayReason());

                var statusSaveModel = PrepareSave(statuses.caseStatus1);
                statusSaveModel.Name = "UpdatedInternalDesc";
                statusSaveModel.ExternalName = "UpdatedExternalDesc";

                var id = (short) statuses.caseStatus1.Id;
                var status = f.Subject.Update(statuses.caseStatus1.Id, statusSaveModel);

                Assert.Equal(status.Result, "success");
                Assert.Equal(statusSaveModel.Name, Db.Set<Status>().Single(_ => _.Id == id).Name);
                Assert.Equal(statusSaveModel.ExternalName, Db.Set<Status>().Single(_ => _.Id == id).ExternalName);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenUpdateModelNotPassed()
            {
                var f = new StatusMaintenanceControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Update(Fixture.Short(), null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveModel", exception.Message);
            }
        }

        public class DeleteStatus : FactBase
        {
            [Fact]
            public void ThrowsArgumentNullExceptionWhenDeleteModelNotPassed()
            {
                var f = new StatusMaintenanceControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Delete(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("deleteStatusModel", exception.Message);
            }
        }

        public class StatusMaintenanceControllerFixture : IFixture<StatusMaintenanceController>
        {
            readonly InMemoryDbContext _db;

            public StatusMaintenanceControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                StatusSupport = Substitute.For<IStatusSupport>();
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
                Subject = new StatusMaintenanceController(db, StatusSupport, LastInternalCodeGenerator);
            }

            public IStatusSupport StatusSupport { get; set; }
            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
            public StatusMaintenanceController Subject { get; }

            public dynamic CreateStatusList()
            {
                var renewalStatus1 = new Status(Fixture.Short(), "CPA to be notified")
                {
                    RenewalFlag = 1,
                    ExternalName = "CPA to be notified"
                }.In(_db);

                var caseStatus1 = new Status(Fixture.Short(), "EP Granted")
                {
                    RenewalFlag = 0,
                    ExternalName = "Granted"
                }.In(_db);

                var renewalStatus2 = new Status(Fixture.Short(), "Renewal overdue")
                {
                    RenewalFlag = 1,
                    ExternalName = "Renewable with extensions"
                }.In(_db);

                var caseStatus2 = new Status(Fixture.Short(), "Certificate received")
                {
                    RenewalFlag = 0,
                    ExternalName = "Registered"
                }.In(_db);

                return new
                {
                    caseStatus1,
                    caseStatus2,
                    renewalStatus1,
                    renewalStatus2
                };
            }
        }
    }
}