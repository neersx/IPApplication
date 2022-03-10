using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using KnownValues = InprotechKaizen.Model.KnownValues;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class PostedWipAdjustorFacts
    {
        public class AdjustWipBatch : FactBase
        {
            [Fact]
            public async Task ReturnsErrorIfFunctionSecurityFails()
            {
                var f = new PostedWipAdjustorFixture(Db);
                f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, Arg.Any<User>(), Arg.Any<int?>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.AdjustWipBatch(new List<WorkInProgress>(), new TimeEntry {StaffId = Fixture.Integer()}, new TimeEntry()));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                await f.AdjustWipCommand.DidNotReceiveWithAnyArgs().SaveAdjustment(Arg.Any<int>(), Arg.Any<string>(),Arg.Any<AdjustWipItem>());
            }

            [Fact]
            public async Task ChecksIfAdjustmentRequired()
            {
                var postedTime = new TimeEntry
                {
                    EntryNo = Fixture.Integer(),
                    StaffId = Fixture.Integer()
                };
                var f = new PostedWipAdjustorFixture(Db);
                await f.Subject.AdjustWipBatch(new List<WorkInProgress>(), postedTime, new TimeEntry());
                await f.AdjustWipCommand.DidNotReceiveWithAnyArgs().SaveAdjustment(Arg.Any<int>(), Arg.Any<string>(),Arg.Any<AdjustWipItem>());
            }
            
            [Theory]
            [InlineData(10, TransactionType.CreditWipAdjustment)]
            [InlineData(12, TransactionType.DebitWipAdjustment)]
            public async Task AdjustsPostedWip(decimal newValue, KnownTransactionReason adjustmentType)
            {
                var time = new TimeEntry {TotalTime = new DateTime(1899, 1, 1, 1, 30, 0), TotalUnits = Fixture.Short(), LocalValue = newValue, NarrativeText = Fixture.String("NewNarrative")};
                var f = new PostedWipAdjustorFixture(Db);
                var staffId = f.SecurityContext.User.NameId;
                f.PostedWip.Balance = 11;
                var postedWipList = new List<WorkInProgress> { f.PostedWip };
                await f.Subject.AdjustWipBatch(postedWipList, time, new TimeEntry {TotalTime = new DateTime(1899, 1, 1, 1, 0, 0)});
                await f.AdjustWipCommand.Received(1).SaveAdjustment(f.CurrentUser.Id, Arg.Any<string>(),Arg.Is<AdjustWipItem>(_ => _.AdjustmentType == (int)adjustmentType &&
                                                                                                                                   _.EntityKey == f.PostedWip.EntityId && _.TransKey == f.PostedWip.TransactionId&& _.WipSeqNo == f.PostedWip.WipSequenceNo &&
                                                                                                                                   _.RequestedByStaffKey == staffId && _.ReasonCode == KnownAccountingReason.IncorrectTimeEntry &&
                                                                                                                                   _.NewLocal == newValue && _.NewTotalTime == time.TotalTime.Value.TimeOfDay && _.NewTotalUnits == time.TotalUnits && _.NewDebitNoteText == time.NarrativeText));
            }

            [Theory]
            [InlineData(10, TransactionType.DebitWipAdjustment)]
            [InlineData(12, TransactionType.CreditWipAdjustment)]
            public async Task AdjustsPostedDiscount(decimal newValue, KnownTransactionReason adjustmentType)
            {
                var time = new TimeEntry {TotalTime = new DateTime(1899, 1, 1, 1, 30, 0), TotalUnits = Fixture.Short(), LocalDiscount = newValue, NarrativeText = Fixture.String("NewNarrative")};
                var f = new PostedWipAdjustorFixture(Db);
                var staffId = f.SecurityContext.User.NameId;
                f.PostedWip.Balance = -11;
                f.PostedWip.IsDiscount = 1;
                var postedWipList = new List<WorkInProgress> { f.PostedWip };
                await f.Subject.AdjustWipBatch(postedWipList, time, new TimeEntry {TotalTime = new DateTime(1899, 1, 1, 1, 0, 0)});
                await f.AdjustWipCommand.Received(1).SaveAdjustment(f.CurrentUser.Id, Arg.Any<string>(),Arg.Is<AdjustWipItem>(_ => _.AdjustmentType == (int)adjustmentType &&
                                                                                                                                   _.EntityKey == f.PostedWip.EntityId && _.TransKey == f.PostedWip.TransactionId&& _.WipSeqNo == f.PostedWip.WipSequenceNo &&
                                                                                                                                   _.RequestedByStaffKey == staffId && _.ReasonCode == KnownAccountingReason.IncorrectTimeEntry &&
                                                                                                                                   _.NewLocal == newValue * -1 && _.NewTotalTime == TimeSpan.Zero && _.NewTotalUnits == null && _.NewNarrativeKey == null));
            }

            [Fact]
            public async Task DiscountNotAdjustedIfTimeIsUnchanged()
            {
                var totalUnits = Fixture.Short();
                var totalTime = TimeSpan.FromHours(1);
                var time = new TimeEntry
                {
                    LocalValue = Fixture.Integer(),
                    LocalDiscount = 11,
                    ForeignDiscount = null,
                    TotalTime = new DateTime(1899, 1, 1, 1, 30, 0),
                    TotalUnits = totalUnits
                };
                var f = new PostedWipAdjustorFixture(Db) {PostedWip = {Balance = -11, IsDiscount = 1, TotalUnits = totalUnits, TotalTime = DateTime.MinValue + totalTime}};
                var postedWipList = new List<WorkInProgress> { f.PostedWip };

                await f.Subject.AdjustWipBatch(postedWipList, time, new TimeEntry {TotalTime = new DateTime(1899, 1, 1, 1, 0, 0)});
                await f.AdjustWipCommand.DidNotReceiveWithAnyArgs().SaveAdjustment(Arg.Any<int>(), Arg.Any<string>(),Arg.Any<AdjustWipItem>());
            }

            [Fact]
            public async Task NotesOnlyChangesDoesNotAdjustWip()
            {
                var totalUnits = Fixture.Short();
                var time = new TimeEntry
                {
                    LocalValue = 11,
                    TotalTime = new DateTime(1899, 1, 1, 1, 1, 0, 0),
                    TotalUnits = totalUnits,
                    Notes = "Test Notes"
                };
                var f = new PostedWipAdjustorFixture(Db) {PostedWip = {Balance = 11, TotalUnits = totalUnits, TotalTime = time.TotalTime}};
                var postedWipList = new List<WorkInProgress> { f.PostedWip };
                await f.Subject.AdjustWipBatch(postedWipList, time, new TimeEntry {TotalTime = time.TotalTime, TotalUnits = totalUnits});
                await f.AdjustWipCommand.DidNotReceiveWithAnyArgs().SaveAdjustment(Arg.Any<int>(), Arg.Any<string>(),Arg.Any<AdjustWipItem>());
            }

            [Theory]
            [InlineData(1, true, 0)]
            [InlineData(0, true, 0)]
            [InlineData(1, false, 0)]
            [InlineData(0, false, 1)]
            public async Task OnlyAdjustsNarrativeForMainWip(int isDiscount, bool isMargin, int adjustedRecords)
            {
                var totalUnits = Fixture.Short();
                var totalTime = new DateTime(1899, 1, 1, 1, 1, 0, 0);
                var narrativeKey = Fixture.Short();
                var narrativeText = Fixture.String();
                var time = new TimeEntry
                {
                    LocalValue = 11,
                    TotalTime = totalTime,
                    TotalUnits = totalUnits,
                    NarrativeNo = narrativeKey,
                    NarrativeText = narrativeText
                };
                var f = new PostedWipAdjustorFixture(Db) {PostedWip = {Balance = 11, TotalUnits = totalUnits, TotalTime = totalTime, IsDiscount = isDiscount, IsMargin = isMargin}};
                var postedWipList = new List<WorkInProgress> { f.PostedWip };
                await f.Subject.AdjustWipBatch(postedWipList, time, new TimeEntry {TotalTime = time.TotalTime, TotalUnits = totalUnits});
                await f.AdjustWipCommand.Received(adjustedRecords).SaveAdjustment(f.SecurityContext.User.Id, Arg.Any<string>(),Arg.Is<AdjustWipItem>(_ => _.AdjustmentType == null && _.NewNarrativeKey == narrativeKey && _.NewDebitNoteText == narrativeText));
            }

            [Fact]
            public async Task TotalTimeConsidersTimeCarriedForward()
            {
                var time = new TimeEntry {TotalTime = new DateTime(1899, 1, 1, 1, 30, 0), TotalUnits = Fixture.Short(), LocalValue = 100, TimeCarriedForward = new DateTime(1899, 1, 1, 6, 00, 0)};
                var f = new PostedWipAdjustorFixture(Db);
                var staffId = f.SecurityContext.User.NameId;
                f.PostedWip.Balance = 11;
                var postedWipList = new List<WorkInProgress> { f.PostedWip };
                await f.Subject.AdjustWipBatch(postedWipList, time, new TimeEntry {TotalTime = new DateTime(1899, 1, 1, 1, 0, 0)});
                await f.AdjustWipCommand.Received(1).SaveAdjustment(f.CurrentUser.Id, Arg.Any<string>(),Arg.Is<AdjustWipItem>(_ => _.AdjustmentType == (int)TransactionType.DebitWipAdjustment &&
                                                                                                                                   _.EntityKey == f.PostedWip.EntityId && _.TransKey == f.PostedWip.TransactionId&& _.WipSeqNo == f.PostedWip.WipSequenceNo &&
                                                                                                                                   _.RequestedByStaffKey == staffId && _.ReasonCode == KnownAccountingReason.IncorrectTimeEntry &&
                                                                                                                                   _.NewLocal == 100 && _.NewTotalTime == new DateTime(1899, 1, 1, 7, 30, 0).TimeOfDay && _.NewTotalUnits == time.TotalUnits && _.NewDebitNoteText == time.NarrativeText));
            }
        }

        public class WipTransfers : FactBase
        {
            [Fact]
            public async Task AdjustsPostedWipCase()
            {
                var totalTime = new DateTime(1899, 1, 1, 1, 1, 0, 0);
                var adjustmentEntry = new RecordableTime { TotalTime = totalTime, TotalUnits = Fixture.Short(), CaseKey = Fixture.Integer()};
                var f = new PostedWipAdjustorFixture(Db);
                var postedWipList = new List<WorkInProgress> {f.PostedWip};
                await f.Subject.TransferWip(postedWipList, adjustmentEntry, TransactionType.CaseWipTransfer);
                await f.AdjustWipCommand.Received(1).SaveAdjustment(f.SecurityContext.User.Id, Arg.Any<string>(),Arg.Is<AdjustWipItem>(_ => _.AdjustmentType == (int)TransactionType.CaseWipTransfer &&
                                                                                                                                            _.EntityKey == f.PostedWip.EntityId && _.TransKey == f.PostedWip.TransactionId && _.WipSeqNo == f.PostedWip.WipSequenceNo &&
                                                                                                                                            _.ReasonCode == KnownAccountingReason.IncorrectTimeEntry &&
                                                                                                                                            _.RequestedByStaffKey == f.CurrentUser.NameId && _.NewCaseKey == adjustmentEntry.CaseKey));
            }

            [Fact]
            public async Task AdjustsPostedWipActivity()
            {
                var totalTime = new DateTime(1899, 1, 1, 1, 1, 0, 0);
                var adjustmentEntry = new RecordableTime { TotalTime = totalTime, TotalUnits = Fixture.Short(), Activity = Fixture.String()};
                var f = new PostedWipAdjustorFixture(Db);
                var postedWipList = new List<WorkInProgress> {f.PostedWip};
                await f.Subject.TransferWip(postedWipList, adjustmentEntry, TransactionType.ActivityWipTransfer);
                await f.AdjustWipCommand.Received(1).SaveAdjustment(f.SecurityContext.User.Id, Arg.Any<string>(),Arg.Is<AdjustWipItem>(_ => _.AdjustmentType == (int)TransactionType.ActivityWipTransfer &&
                                                                                                                                            _.EntityKey == f.PostedWip.EntityId && _.TransKey == f.PostedWip.TransactionId && _.WipSeqNo == f.PostedWip.WipSequenceNo &&
                                                                                                                                            _.ReasonCode == KnownAccountingReason.IncorrectTimeEntry &&
                                                                                                                                            _.RequestedByStaffKey == f.CurrentUser.NameId && _.NewActivityCode == adjustmentEntry.Activity));
            }

            [Theory]
            [InlineData("")]
            [InlineData(null)]
            [InlineData("DISCOUNT")]
            public async Task AdjustsPostedDiscountActivity(string discountWipCode)
            {
                var totalTime = new DateTime(1899, 1, 1, 1, 1, 0, 0);
                var adjustmentEntry = new RecordableTime { TotalTime = totalTime, TotalUnits = Fixture.Short(), Activity = Fixture.String()};
                var f = new PostedWipAdjustorFixture(Db) {PostedWip = {IsDiscount = Decimal.One}};
                f.SiteControlReader.Read<string>(SiteControls.DiscountWIPCode).Returns(discountWipCode);
                var postedWipList = new List<WorkInProgress> {f.PostedWip};
                await f.Subject.TransferWip(postedWipList, adjustmentEntry, TransactionType.ActivityWipTransfer);
                await f.AdjustWipCommand.Received(1).SaveAdjustment(f.SecurityContext.User.Id, Arg.Any<string>(),Arg.Is<AdjustWipItem>(_ => _.AdjustmentType == (int)TransactionType.ActivityWipTransfer &&
                                                                                                                                            _.EntityKey == f.PostedWip.EntityId && _.TransKey == f.PostedWip.TransactionId && _.WipSeqNo == f.PostedWip.WipSequenceNo &&
                                                                                                                                            _.ReasonCode == KnownAccountingReason.IncorrectTimeEntry &&
                                                                                                                                            _.RequestedByStaffKey == f.CurrentUser.NameId && _.NewActivityCode == (discountWipCode ?? adjustmentEntry.Activity)));
            }
        }

        public class AdjustToZero : FactBase
        {
            [Theory]
            [InlineData(true, 0, TransactionType.DebitWipAdjustment)]
            [InlineData(true, -1, TransactionType.DebitWipAdjustment)]
            [InlineData(true, 1, TransactionType.CreditWipAdjustment)]
            [InlineData(false, 0, TransactionType.DebitWipAdjustment)]
            [InlineData(false, -1, TransactionType.DebitWipAdjustment)]
            [InlineData(false, 1, TransactionType.CreditWipAdjustment)]
            public async Task AdjustsWipToZero(bool isDiscount, int balance, TransactionType expectedAdjustment)
            {
                var f = new PostedWipAdjustorFixture(Db) {PostedWip = {IsDiscount = isDiscount ? 1 : 0, LocalValue = Fixture.Decimal(), Balance = balance, CaseId = Fixture.Integer(), WipCode = Fixture.RandomString(6)}};
                var postedWipList = new List<WorkInProgress> {f.PostedWip};
                await f.Subject.AdjustWipBatchToZero(postedWipList);
                await f.AdjustWipCommand.Received(1).SaveAdjustment(f.SecurityContext.User.Id, Arg.Any<string>(),Arg.Is<AdjustWipItem>(_ => _.AdjustmentType == (int)expectedAdjustment &&
                                                                                                                                            _.EntityKey == f.PostedWip.EntityId &&
                                                                                                                                            _.TransKey == f.PostedWip.TransactionId &&
                                                                                                                                            _.WipSeqNo == f.PostedWip.WipSequenceNo &&
                                                                                                                                            _.NewCaseKey == null &&
                                                                                                                                            _.NewActivityCode == null &&
                                                                                                                                            _.NewLocal == 0 && 
                                                                                                                                            _.NewForeign == 0 &&
                                                                                                                                            _.NewTotalTime == TimeSpan.Zero &&
                                                                                                                                            _.NewTotalUnits == (!isDiscount ? 0 : (int?)null) &&
                                                                                                                                            _.IsAdjustToZero == !isDiscount &&
                                                                                                                                            _.ReasonCode == KnownAccountingReason.IncorrectTimeEntry &&
                                                                                                                                            _.TransDate == Fixture.Today() &&
                                                                                                                                            _.RequestedByStaffKey == f.CurrentUser.NameId));
            }
        }

        public class PostedWipAdjustorFixture : IFixture<PostedWipAdjustor>
        {
            public PostedWipAdjustorFixture(InMemoryDbContext db)
            {
                PostedWip = new WorkInProgress { EntityId = Fixture.Integer(), TransactionId = Fixture.Integer(), IsDiscount = 0, IsMargin = false, LogDateTimeStamp = null };
                AdjustWipCommand = Substitute.For<IAdjustWipCommand>();
                SecurityContext = Substitute.For<ISecurityContext>();
                CurrentUser = new UserBuilder(db).Build();
                SecurityContext.User.Returns(CurrentUser);
                SiteControlReader = Substitute.For<ISiteControlReader>();
                FunctionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();
                FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, Arg.Any<User>(), Arg.Any<int?>()).Returns(true);
                Today = Substitute.For<Func<DateTime>>();
                Today().Returns(Fixture.Today());
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new PostedWipAdjustor(AdjustWipCommand, SecurityContext, preferredCultureResolver, SiteControlReader, FunctionSecurityProvider, db, Today);
            }

            public Func<DateTime> Today { get; set; }
            public User CurrentUser { get; set; }
            public WorkInProgress PostedWip {get; set; }
            public IFunctionSecurityProvider FunctionSecurityProvider { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public IAdjustWipCommand AdjustWipCommand { get; set; }
            public PostedWipAdjustor Subject { get; }
        }
    }
}