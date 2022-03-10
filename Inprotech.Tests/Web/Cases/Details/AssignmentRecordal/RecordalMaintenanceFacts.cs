using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.ApplyRecordal;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details.AssignmentRecordal
{
    public class RecordalMaintenanceFacts : FactBase
    {
        class RecordalMaintenanceFixture : IFixture<RecordalMaintenance>
        {
            public RecordalMaintenanceFixture(InMemoryDbContext db)
            {
                Helper = Substitute.For<IAssignmentRecordalHelper>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                PolicingEngine = Substitute.For<IPolicingEngine>();
                SecurityContext = Substitute.For<ISecurityContext>();
                SystemTime = Substitute.For<Func<DateTime>>();
                Bus = Substitute.For<IBus>();
                Resolver = Substitute.For<IPreferredCultureResolver>();
                StaticTranslator = Substitute.For<IStaticTranslator>();
                Subject = new RecordalMaintenance(db, Helper, SiteControlReader, PolicingEngine, SecurityContext, SystemTime, Resolver, Bus, StaticTranslator);
                SecurityContext.User.Returns(new User {Profile = new Profile()});
            }

            public IAssignmentRecordalHelper Helper { get; }
            public ISiteControlReader SiteControlReader { get; }
            public IPolicingEngine PolicingEngine { get; }
            public ISecurityContext SecurityContext { get; }
            public IBus Bus { get; }
            public IStaticTranslator StaticTranslator { get; }
            public RecordalMaintenance Subject { get; }
            Func<DateTime> SystemTime { get; }
            IPreferredCultureResolver Resolver { get; }
        }

        Case SetupData(out Case rc1, out Event @event, out RecordalAffectedCase afc1, out RecordalAffectedCase afc2)
        {
            var @case = new CaseBuilder().Build().In(Db);
            rc1 = new CaseBuilder().Build().In(Db);
            @event = new Event().In(Db);
            var action = new ActionBuilder().Build().In(Db);
            var recordalType1 = new RecordalType {RequestEventId = @event.Id, RequestEvent = @event, RequestActionId = action.Code}.In(Db);
            var recordalType2 = new RecordalType().In(Db);
            afc1 = new RecordalAffectedCase {CaseId = @case.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalType = recordalType1, RecordalTypeNo = recordalType1.Id, RecordalStepSeq = 1, SequenceNo = 1, Status = AffectedCaseStatus.NotYetFiled}.In(Db);
            afc2 = new RecordalAffectedCase {CaseId = @case.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalType = recordalType2, RecordalTypeNo = recordalType2.Id, RecordalStepSeq = 2, SequenceNo = 2, Status = AffectedCaseStatus.NotYetFiled}.In(Db);
            new RecordalStep {CaseId = @case.Id, Id = 1, RecordalType = recordalType1, TypeId = recordalType1.Id, StepId = 1}.In(Db);
            new RecordalStep {CaseId = @case.Id, Id = 2, RecordalType = recordalType2, TypeId = recordalType2.Id, StepId = 2}.In(Db);
            return @case;
        }

        [Fact]
        public async Task ShouldRejectRecordal()
        {
            var @case = SetupData(out var rc1, out _, out var afc1, out var afc2);
            afc1.Status = AffectedCaseStatus.Filed;
            afc2.Status = AffectedCaseStatus.Filed;
            var name1 = new NameBuilder(Db).Build().In(Db);
            var name2 = new NameBuilder(Db).Build().In(Db);
            var element = new Element {Code = KnownRecordalElementValues.NewName, Id = 1, EditAttribute = KnownRecordalEditAttributes.Mandatory, Name = "New Name"}.In(Db);
            new RecordalStepElement {CaseId = @case.Id, EditAttribute = KnownRecordalEditAttributes.Mandatory, Element = element, ElementId = element.Id, ElementValue = name1.Id + "," + name2.Id, RecordalStepId = 1, NameTypeCode = KnownNameTypes.Owner}.In(Db);
            var nameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.NewOwner}.Build().In(Db);
            new CaseNameBuilder(Db) {Case = rc1, Name = name1, NameType = nameType}.Build().In(Db);
            new CaseNameBuilder(Db) {Case = rc1, Name = name2, NameType = nameType}.Build().In(Db);

            var f = new RecordalMaintenanceFixture(Db);
            var model = new SaveRecordalRequest
            {
                CaseId = @case.Id,
                RequestedDate = DateTime.Now,
                RequestType = RecordalRequestType.Reject,
                SeqIds = new[] {1, 2}
            };

            var result = await f.Subject.SaveRequestRecordal(model);
            Assert.Equal("success", result.Result);
            Assert.Equal(AffectedCaseStatus.Rejected, afc1.Status);
            Assert.Equal(model.RequestedDate, afc1.RecordDate);
            Assert.Equal(AffectedCaseStatus.Rejected, afc2.Status);
            Assert.Equal(model.RequestedDate, afc2.RecordDate);

            f.Helper.Received(1).RemoveNewOwners(afc1.RelatedCase, name1.Id + "," + name2.Id);
        }

        [Fact]
        public async Task ShouldRequestRecordal()
        {
            var @case = SetupData(out var rc1, out var @event, out var afc1, out var afc2);
            var f = new RecordalMaintenanceFixture(Db);
            var model = new SaveRecordalRequest
            {
                CaseId = @case.Id,
                RequestedDate = DateTime.Now,
                RequestType = RecordalRequestType.Request,
                SeqIds = new[] {1, 2}
            };
            f.SiteControlReader.Read<bool>(Arg.Any<string>()).Returns(true);
            f.PolicingEngine.CreateBatch().Returns(1);

            var result = await f.Subject.SaveRequestRecordal(model);
            Assert.Equal("success", result.Result);
            Assert.Equal(AffectedCaseStatus.Filed, afc1.Status);
            Assert.Equal(model.RequestedDate, afc1.RequestDate);
            Assert.Equal(AffectedCaseStatus.Filed, afc2.Status);
            Assert.Equal(model.RequestedDate, afc2.RequestDate);

            f.PolicingEngine.Received(1).CreateBatch();
            var insertedCaseEvent = Db.Set<CaseEvent>().First();
            Assert.NotNull(insertedCaseEvent);
            Assert.Equal(rc1.Id, insertedCaseEvent.CaseId);
            Assert.Equal(@event.Id, insertedCaseEvent.EventNo);
            Assert.Equal(1, insertedCaseEvent.Cycle);
            Assert.Equal(1, insertedCaseEvent.IsOccurredFlag);
            Assert.Equal(model.RequestedDate, insertedCaseEvent.EventDate);

            f.PolicingEngine.Received(1).PoliceEvent(Arg.Any<CaseEvent>(), Arg.Any<int?>(), 1, Arg.Any<string>(), TypeOfPolicingRequest.OpenAnAction);
            f.PolicingEngine.Received(1).PoliceEvent(Arg.Any<CaseEvent>(), Arg.Any<int?>(), 1, Arg.Any<string>(), TypeOfPolicingRequest.PoliceOccurredEvent);
            await f.PolicingEngine.Received(1).PoliceWithoutTransaction(1);
        }

        [Fact]
        public async Task ShouldRequestRecordalAndUpdateCaseEvent()
        {
            var @case = SetupData(out var rc1, out var @event, out var afc1, out _);
            var caseEvent = new CaseEvent(rc1.Id, @event.Id, 2).In(Db);
            var f = new RecordalMaintenanceFixture(Db);
            var model = new SaveRecordalRequest
            {
                CaseId = @case.Id,
                RequestedDate = DateTime.Now,
                RequestType = RecordalRequestType.Request,
                SeqIds = new[] {1, 2}
            };
            f.SiteControlReader.Read<bool>(Arg.Any<string>()).Returns(false);

            var result = await f.Subject.SaveRequestRecordal(model);
            Assert.Equal("success", result.Result);
            Assert.Equal(AffectedCaseStatus.Filed, afc1.Status);
            Assert.Equal(model.RequestedDate, afc1.RequestDate);

            f.PolicingEngine.DidNotReceive().CreateBatch();
            Assert.Equal(1, caseEvent.IsOccurredFlag);
            Assert.Equal(model.RequestedDate, caseEvent.EventDate);

            f.PolicingEngine.Received(1).PoliceEvent(Arg.Any<CaseEvent>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<string>(), TypeOfPolicingRequest.OpenAnAction);
            f.PolicingEngine.Received(1).PoliceEvent(Arg.Any<CaseEvent>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<string>(), TypeOfPolicingRequest.PoliceOccurredEvent);
            await f.PolicingEngine.DidNotReceive().PoliceWithoutTransaction(1);
        }

        [Fact]
        public async Task ShouldReturnAffectedCasesForRequestRecordal()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var rc1 = new CaseBuilder().Build().In(Db);
            var recordalType1 = new RecordalType().In(Db);
            var recordalType2 = new RecordalType().In(Db);
            new RecordalAffectedCase {CaseId = @case.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalType = recordalType1, RecordalTypeNo = recordalType1.Id, RecordalStepSeq = 1, SequenceNo = 1, Status = AffectedCaseStatus.NotYetFiled}.In(Db);
            new RecordalAffectedCase {CaseId = @case.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalType = recordalType2, RecordalTypeNo = recordalType2.Id, RecordalStepSeq = 2, SequenceNo = 2, Status = AffectedCaseStatus.Filed}.In(Db);
            new RecordalStep {CaseId = @case.Id, Id = 1, RecordalType = recordalType1, TypeId = recordalType1.Id, StepId = 1}.In(Db);
            new RecordalStep {CaseId = @case.Id, Id = 2, RecordalType = recordalType2, TypeId = recordalType2.Id, StepId = 2}.In(Db);
            var f = new RecordalMaintenanceFixture(Db);
            var model = new RecordalRequest
            {
                CaseId = @case.Id,
                RequestType = RecordalRequestType.Request,
                SelectedRowKeys = new List<string> {$"{@case.Id}^rc1.Id^{rc1.CountryId}^{rc1.CurrentOfficialNumber}"}
            };
            var affectedCases = Db.Set<RecordalAffectedCase>();
            f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);
            var result = (await f.Subject.GetAffectedCasesForRequestRecordal(model)).ToList();
            Assert.Equal(2, result.Count);
            var first = result.First();
            Assert.Equal(1, first.SequenceNo);
            Assert.Equal(recordalType1.RecordalTypeName, first.RecordalType);
            Assert.Equal(1, first.StepId);
            Assert.True(first.IsEditable);
            var last = result[1];
            Assert.Equal(2, last.SequenceNo);
            Assert.False(last.IsEditable);
            Assert.Equal(AffectedCaseStatus.Filed, last.Status);
        }

        [Fact]
        public async Task ShouldSendMessageForApplyRecordal()
        {
            var @case = SetupData(out _, out _, out var afc1, out var afc2);
            afc1.Status = AffectedCaseStatus.Filed;
            afc2.Status = AffectedCaseStatus.Filed;
            var f = new RecordalMaintenanceFixture(Db);
            var model = new SaveRecordalRequest
            {
                CaseId = @case.Id,
                RequestedDate = DateTime.Now,
                RequestType = RecordalRequestType.Apply,
                SeqIds = new[] {1, 2}
            };

            f.StaticTranslator.Translate("caseview.affectedCases.applyRecordalProcessed", Arg.Any<string[]>()).Returns("Success");
            f.StaticTranslator.Translate("caseview.affectedCases.applyRecordalFailed", Arg.Any<string[]>()).Returns("Error");
            await f.Subject.SaveRequestRecordal(model);
            f.StaticTranslator.Received(1).Translate("caseview.affectedCases.applyRecordalProcessed", Arg.Any<string[]>());
            f.StaticTranslator.Received(1).Translate("caseview.affectedCases.applyRecordalFailed", Arg.Any<string[]>());
            await f.Bus.Received(1).PublishAsync(Arg.Is<ApplyRecordalArgs>(_ => _.RunBy == f.SecurityContext.User.Id
                                                                                && _.RecordalCase == @case.Id
                                                                                && _.RecordalDate == model.RequestedDate
                                                                                && _.SuccessMessage == "Success"
                                                                                && _.ErrorMessage == "Error"
                                                                                && _.RecordalSeqIds == afc1.SequenceNo + "," + afc2.SequenceNo
                                                                                && _.RecordalStatus == AffectedCasesStatus.Recorded));
        }

        [Fact]
        public async Task ShouldThrowExceptionIfAffectedCasesNotFound()
        {
            var f = new RecordalMaintenanceFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.SaveRequestRecordal(new SaveRecordalRequest {CaseId = Fixture.Integer(), SeqIds = new[] {1, 2}}));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldThrowExceptionIfModelIsNullForGetRequestRecordal()
        {
            var f = new RecordalMaintenanceFixture(Db);
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.GetAffectedCasesForRequestRecordal(null));
        }

        [Fact]
        public async Task ShouldThrowExceptionIfModelIsNullForSaveRequestRecordal()
        {
            var f = new RecordalMaintenanceFixture(Db);
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.SaveRequestRecordal(null));
        }
    }
}