using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Infrastructure.Policy;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class WipAdjustmentsFacts
    {
        public class WipAdjustmentsFixture : IFixture<WipAdjustments>
        {
            public WipAdjustmentsFixture(InMemoryDbContext db)
            {
                GetWipItemCommand = Substitute.For<IGetWipItemCommand>();
                SplitWipCommand = Substitute.For<ISplitWipCommand>();
                AdjustWipCommand = Substitute.For<IAdjustWipCommand>();
                WipDefaulting = Substitute.For<IWipDefaulting>();
                CurrentNames = Substitute.For<ICurrentNames>();
                ApplicationAlerts = Substitute.For<IApplicationAlerts>();
                ValidatePostDates = Substitute.For<IValidatePostDates>();

                var siteDateFormat = Substitute.For<ISiteDateFormat>();
                siteDateFormat.Resolve(Arg.Any<string>())
                              .Returns("yyyy-MMM-dd");

                Subject = new WipAdjustments(db,
                                             Substitute.For<ILogger<WipAdjustments>>(),
                                             ValidatePostDates,
                                             siteDateFormat,
                                             GetWipItemCommand,
                                             WipDefaulting,
                                             AdjustWipCommand,
                                             SplitWipCommand,
                                             ApplicationAlerts,
                                             CurrentNames,
                                             Fixture.Today);
            }

            public IGetWipItemCommand GetWipItemCommand { get; }

            public IWipDefaulting WipDefaulting { get; }

            public ISplitWipCommand SplitWipCommand { get; }

            public IAdjustWipCommand AdjustWipCommand { get; }

            public IApplicationAlerts ApplicationAlerts { get; }

            public ICurrentNames CurrentNames { get; }

            public IValidatePostDates ValidatePostDates { get; }

            public WipAdjustments Subject { get; }

            public WipAdjustmentsFixture WithValidPostDate()
            {
                ValidatePostDates.For(Arg.Any<DateTime>(), Arg.Any<SystemIdentifier>())
                                 .Returns((true, false, string.Empty));
                return this;
            }

            public WipAdjustmentsFixture WithInvalidPostDate(string code, bool isWarning)
            {
                ValidatePostDates.For(Arg.Any<DateTime>(), Arg.Any<SystemIdentifier>())
                                 .Returns((false, isWarning, code));
                return this;
            }

            public WipAdjustmentsFixture WithApplicationAlert(string alertCode, string alertMessage)
            {
                ApplicationAlerts.TryParse(Arg.Any<string>(), out var alerts)
                                 .Returns(x =>
                                 {
                                     x[1] = new[]
                                     {
                                         new ApplicationAlert
                                         {
                                             AlertID = alertCode,
                                             Message = alertMessage
                                         }
                                     };

                                     return true;
                                 });
                return this;
            }

            public WipAdjustmentsFixture WithWipAdjusted(AdjustWipItemDto adjustWipItem, int newTransKey)
            {
                AdjustWipCommand.SaveAdjustment(Arg.Any<int>(), Arg.Any<string>(), adjustWipItem, false)
                                .Returns(new WipAdjustOrSplitResult
                                {
                                    NewTransKey = newTransKey
                                });

                return this;
            }

            public WipAdjustmentsFixture WithWipSplit(SplitWipItem splitWipItem, int newTransKey, short newWipSeqKey)
            {
                SplitWipCommand.Split(Arg.Any<int>(), Arg.Any<string>(), splitWipItem)
                               .Returns(new WipAdjustOrSplitResult
                               {
                                   NewTransKey = newTransKey,
                                   NewWipSeqKey = newWipSeqKey
                               });

                return this;
            }

            public WipAdjustmentsFixture WithWipSplitError(SplitWipItem splitWipItem, int errorCode, string errorMessage)
            {
                SplitWipCommand.Split(Arg.Any<int>(), Arg.Any<string>(), splitWipItem)
                               .Returns(new WipAdjustOrSplitResult
                               {
                                   ErrorCode = errorCode,
                                   Error = errorMessage
                               });

                return this;
            }
        }

        public class CaseHasMultipleDebtorsMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnTrueIfCasesContainMoreThanOneDebtor()
            {
                var fixture = new WipAdjustmentsFixture(Db);

                var @case = new CaseBuilder().Build().In(Db);
                var debtorNameType = new NameType(KnownNameTypes.Debtor, "Debtor").In(Db);
                new CaseNameBuilder(Db) { NameType = debtorNameType }.BuildWithCase(@case).In(Db);
                new CaseNameBuilder(Db) { NameType = debtorNameType }.BuildWithCase(@case).In(Db);

                fixture.CurrentNames.For(@case.Id, KnownNameTypes.Debtor)
                       .Returns(Db.Set<CaseName>().Where(_ => _.NameType.NameTypeCode == KnownNameTypes.Debtor));

                var r = await fixture.Subject.CaseHasMultipleDebtors(@case.Id);

                Assert.True(r);
            }

            [Fact]
            public async Task ShouldReturnFalseIfThereIsOnlyOneDebtor()
            {
                var caseKey = Fixture.Integer();

                var fixture = new WipAdjustmentsFixture(Db);

                var @case = new CaseBuilder().Build().In(Db);
                var debtorNameType = new NameType(KnownNameTypes.Debtor, "Debtor").In(Db);
                new CaseNameBuilder(Db) { NameType = debtorNameType }.BuildWithCase(@case).In(Db);

                fixture.CurrentNames.For(@case.Id, KnownNameTypes.Debtor)
                       .Returns(Db.Set<CaseName>().Where(_ => _.NameType.NameTypeCode == KnownNameTypes.Debtor));

                fixture.CurrentNames.For(caseKey, KnownNameTypes.Debtor)
                       .Returns(Db.Set<CaseName>().Where(_ => _.NameType.NameTypeCode == KnownNameTypes.Debtor));

                var r = await fixture.Subject.CaseHasMultipleDebtors(caseKey);

                Assert.False(r);
            }
        }

        public class ValidateItemDateMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnValidIfIndicated()
            {
                var fixture = new WipAdjustmentsFixture(Db)
                    .WithValidPostDate();

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Empty(r.ValidationErrorList);
            }

            [Theory]
            [InlineData("AC124", "The item date is not within the period it will be posted to.  Please check that the transaction is dated correctly.")]
            public async Task ShouldReturnWarningWithMessageIfIndicated(string warningCode, string warningMessage)
            {
                var fixture = new WipAdjustmentsFixture(Db)
                    .WithInvalidPostDate(warningCode, true);

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Equal(warningCode, r.ValidationErrorList.Single().WarningCode);
                Assert.Equal(warningMessage, r.ValidationErrorList.Single().WarningDescription);
            }

            [Theory]
            [InlineData("AC126", "An accounting period could not be determined for the given date. Please check the period definitions and try again.")]
            [InlineData("AC208", "The item date cannot be in the future. It must be within the current accounting period or up to and including the current date.")]
            public async Task ShouldReturnErrorWithMessageIfIndicated(string errorCode, string errorMessage)
            {
                var fixture = new WipAdjustmentsFixture(Db)
                    .WithInvalidPostDate(errorCode, false);

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Equal(errorCode, r.ValidationErrorList.Single().ErrorCode);
                Assert.Equal(errorMessage, r.ValidationErrorList.Single().ErrorDescription);
            }
        }

        public class GetWipDefaultsMethod : FactBase
        {
            [Fact]
            public async Task ShouldPassWipTemplateFilterCorrectly()
            {
                var caseKey = Fixture.Integer();
                var activityKey = Fixture.String();
                var wipDefaultResult = new WipDefaults();
                var fixture = new WipAdjustmentsFixture(Db);

                fixture.WipDefaulting.ForActivity(Arg.Any<WipTemplateFilterCriteria>(), caseKey, activityKey)
                       .Returns(wipDefaultResult);

                var r = await fixture.Subject.GetWipDefaults(caseKey, activityKey);

                Assert.Equal(wipDefaultResult, r);

                fixture.WipDefaulting
                       .Received(1)
                       .ForActivity(Arg.Is<WipTemplateFilterCriteria>(
                                                                      f => f.ContextCriteria.CaseKey == caseKey &&
                                                                           f.UsedByApplication.IsWip == true &&
                                                                           f.WipCategory.IsDisbursements == true &&
                                                                           f.WipCategory.IsOverheads == true &&
                                                                           f.WipCategory.IsServices == true), caseKey, activityKey)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GetItemToAdjustMethod : FactBase
        {
            readonly string _culture = Fixture.String();
            readonly int _entityKey = Fixture.Integer();
            readonly int _identityId = Fixture.Integer();
            readonly int _transKey = Fixture.Integer();
            readonly short _wipSeqKey = Fixture.Short();

            [Fact]
            public async Task ShouldThrowWipItemCommandReturnsGenericError()
            {
                var fixture = new WipAdjustmentsFixture(Db);

                fixture.GetWipItemCommand
                       .When(_ => _.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey))
                       .Do(_ => throw new Exception("bummer"));

                var r = await Assert.ThrowsAnyAsync<Exception>(
                                                               async () => await fixture.Subject.GetItemToAdjust(_identityId, _culture, _entityKey, _transKey, _wipSeqKey));

                Assert.Equal("bummer", r.Message);
            }

            [Fact]
            public async Task ShouldReturnDatabaseAlerts()
            {
                var fixture = new WipAdjustmentsFixture(Db)
                    .WithApplicationAlert("AC29", "WIP Item has been changed or removed. Please reload the WIP item and try again.");

                fixture.GetWipItemCommand
                       .When(_ => _.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey))
                       .Do(_ =>
                       {
                           throw new SqlExceptionBuilder()
                                 .WithApplicationAlert(
                                                       "AC29",
                                                       "WIP Item has been changed or removed. Please reload the WIP item and try again.")
                                 .Build();
                       });

                var r = await fixture.Subject.GetItemToAdjust(_identityId, _culture, _entityKey, _transKey, _wipSeqKey);

                Assert.Equal("WIP Item has been changed or removed. Please reload the WIP item and try again.", r.Alerts[0]);
            }

            [Fact]
            public async Task ShouldReturnWipItemReadyForAdjustment()
            {
                var wip = new WipItem
                {
                    EntityKey = _entityKey,
                    TransKey = _transKey,
                    WIPSeqKey = _wipSeqKey,
                    LogDateTimeStamp = Fixture.PastDate(),
                    RequestedByStaffKey = Fixture.Integer(),
                    RequestedByStaffCode = Fixture.String(),
                    RequestedByStaffName = Fixture.String(),
                    NarrativeKey = Fixture.Integer(),
                    NarrativeCode = Fixture.String(),
                    NarrativeTitle = Fixture.String(),
                    DebitNoteText = Fixture.String()
                };

                var fixture = new WipAdjustmentsFixture(Db);

                fixture.GetWipItemCommand.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey)
                       .Returns(wip);

                var r = await fixture.Subject.GetItemToAdjust(_identityId, _culture, _entityKey, _transKey, _wipSeqKey);

                Assert.Equal(wip, r.AdjustWipItem.OriginalWIPItem);
                Assert.Equal(Fixture.Today(), r.AdjustWipItem.TransDate);
                Assert.Equal(_entityKey, r.AdjustWipItem.EntityKey);
                Assert.Equal(_transKey, r.AdjustWipItem.TransKey);
                Assert.Equal(_wipSeqKey, r.AdjustWipItem.WIPSeqKey);
                Assert.Equal(wip.LogDateTimeStamp, r.AdjustWipItem.LogDateTimeStamp);
                Assert.Equal(TransactionType.DebitWipAdjustment, r.AdjustWipItem.AdjustmentType);
                Assert.Equal(wip.RequestedByStaffKey, r.AdjustWipItem.RequestedByStaffKey);
                Assert.Equal(wip.RequestedByStaffCode, r.AdjustWipItem.RequestedByStaffCode);
                Assert.Equal(wip.RequestedByStaffName, r.AdjustWipItem.RequestedByStaffName);
                Assert.Equal(wip.NarrativeKey, r.AdjustWipItem.NewNarrativeKey);
                Assert.Equal(wip.NarrativeCode, r.AdjustWipItem.NewNarrativeCode);
                Assert.Equal(wip.NarrativeTitle, r.AdjustWipItem.NewNarrativeTitle);
                Assert.Equal(wip.DebitNoteText, r.AdjustWipItem.NewDebitNoteText);
            }

            [Theory]
            [InlineData(TransactionStatus.Active, false, null, false, "discount flag must be true")]
            [InlineData(TransactionStatus.Active, null, 0, false, "discount flag must be true")]
            [InlineData(TransactionStatus.Active, true, 1, false, "margin flag must not be true")]
            [InlineData(TransactionStatus.Draft, false, 1, false, "status must be active")]
            [InlineData(TransactionStatus.Locked, false, 1, false, "status must be active")]
            [InlineData(TransactionStatus.Reversed, false, 1, false, "status must be active")]
            public async Task ShouldIndicateWipDiscountAvailableIfDiscountItemIsAvailable(TransactionStatus status, bool? marginFlag, int? discountFlag, bool expected, string reason)
            {
                new WorkInProgress
                {
                    /* Wip is available for discount transfer */
                    EntityId = _entityKey,
                    TransactionId = _transKey,
                    WipSequenceNo = _wipSeqKey,
                    IsDiscount = 0,
                    IsMargin = false
                }.In(Db);

                new WorkInProgress
                {
                    EntityId = _entityKey,
                    TransactionId = _transKey,
                    WipSequenceNo = (short)(_wipSeqKey - 1),
                    IsDiscount = discountFlag,
                    IsMargin = marginFlag,
                    Status = status
                }.In(Db);

                var wip = new WipItem
                {
                    EntityKey = _entityKey,
                    TransKey = _transKey,
                    WIPSeqKey = _wipSeqKey
                };

                var fixture = new WipAdjustmentsFixture(Db);

                fixture.GetWipItemCommand.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey)
                       .Returns(wip);

                var r = await fixture.Subject.GetItemToAdjust(_identityId, _culture, _entityKey, _transKey, _wipSeqKey);

                Assert.Equal(expected, r.AdjustWipItem.IsDiscountItemAvailable);
            }

            [Theory]
            [InlineData(false, null, true, "all good")]
            [InlineData(null, 0, true, "all good")]
            [InlineData(true, null, false, "margin flag must not be true")]
            [InlineData(null, 1, false, "discount flag must not be 1")]
            public async Task ShouldIndicateWipDiscountAvailableForTransfer(bool? marginFlag, int? discountFlag, bool expected, string reason)
            {
                new WorkInProgress
                {
                    EntityId = _entityKey,
                    TransactionId = _transKey,
                    WipSequenceNo = _wipSeqKey,
                    IsDiscount = discountFlag,
                    IsMargin = marginFlag
                }.In(Db);

                new WorkInProgress
                {
                    /* discount item - created to indicate DiscountItem is available */
                    EntityId = _entityKey,
                    TransactionId = _transKey,
                    WipSequenceNo = (short)(_wipSeqKey - 1),
                    Status = TransactionStatus.Active,
                    IsDiscount = 1
                }.In(Db);

                var wip = new WipItem
                {
                    EntityKey = _entityKey,
                    TransKey = _transKey,
                    WIPSeqKey = _wipSeqKey
                };

                var fixture = new WipAdjustmentsFixture(Db);

                fixture.GetWipItemCommand.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey)
                       .Returns(wip);

                var r = await fixture.Subject.GetItemToAdjust(_identityId, _culture, _entityKey, _transKey, _wipSeqKey);

                Assert.Equal(expected, r.AdjustWipItem.IsDiscountItemAvailable);
            }
        }

        public class GetItemToSplitMethod : FactBase
        {
            readonly string _culture = Fixture.String();
            readonly int _entityKey = Fixture.Integer();
            readonly int _identityId = Fixture.Integer();
            readonly int _transKey = Fixture.Integer();
            readonly short _wipSeqKey = Fixture.Short();

            [Fact]
            public async Task ShouldThrowWipItemCommandReturnsGenericError()
            {
                var fixture = new WipAdjustmentsFixture(Db);

                fixture.GetWipItemCommand
                       .When(_ => _.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey))
                       .Do(_ => throw new Exception("bummer"));

                var r = await Assert.ThrowsAnyAsync<Exception>(
                                                               async () => await fixture.Subject.GetItemToSplit(_identityId, _culture, _entityKey, _transKey, _wipSeqKey));

                Assert.Equal("bummer", r.Message);
            }

            [Fact]
            public async Task ShouldReturnDatabaseAlerts()
            {
                var fixture = new WipAdjustmentsFixture(Db)
                    .WithApplicationAlert("AC29", "WIP Item has been changed or removed. Please reload the WIP item and try again.");

                fixture.GetWipItemCommand
                       .When(_ => _.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey))
                       .Do(_ =>
                       {
                           throw new SqlExceptionBuilder()
                                 .WithApplicationAlert(
                                                       "AC29",
                                                       "WIP Item has been changed or removed. Please reload the WIP item and try again.")
                                 .Build();
                       });

                var r = await fixture.Subject.GetItemToSplit(_identityId, _culture, _entityKey, _transKey, _wipSeqKey);

                Assert.Equal(_entityKey, r.EntityKey);
                Assert.Equal(_transKey, r.TransKey);
                Assert.Equal(_wipSeqKey, r.WipSeqKey);
                Assert.Equal("WIP Item has been changed or removed. Please reload the WIP item and try again.", r.Alerts[0]);
            }

            [Fact]
            public async Task ShouldEnsureSignsOrReversedWhenGettingCreditWip()
            {
                var fixture = new WipAdjustmentsFixture(Db);

                fixture.GetWipItemCommand.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey)
                       .Returns(new WipItem
                       {
                           EntityKey = _entityKey,
                           TransKey = _transKey,
                           WIPSeqKey = _wipSeqKey,
                           Balance = -1000,
                           LocalValue = -1000,
                           ForeignBalance = -500,
                           ForeignValue = -500
                       });

                var r = await fixture.Subject.GetItemToSplit(_identityId, _culture, _entityKey, _transKey, _wipSeqKey);

                Assert.Equal(1000, r.Balance);
                Assert.Equal(1000, r.LocalValue);
                Assert.Equal(500, r.ForeignBalance);
                Assert.Equal(500, r.ForeignValue);
                Assert.True(r.IsCreditWip);
            }

            [Fact]
            public async Task ShouldEnsureSignsAreAsReturnedForOtherWipItems()
            {
                var fixture = new WipAdjustmentsFixture(Db);

                fixture.GetWipItemCommand.GetWipItem(_identityId, _culture, _entityKey, _transKey, _wipSeqKey)
                       .Returns(new WipItem
                       {
                           EntityKey = _entityKey,
                           TransKey = _transKey,
                           WIPSeqKey = _wipSeqKey,
                           Balance = 1000,
                           LocalValue = 1000,
                           ForeignBalance = 500,
                           ForeignValue = 500
                       });

                var r = await fixture.Subject.GetItemToSplit(_identityId, _culture, _entityKey, _transKey, _wipSeqKey);

                Assert.Equal(1000, r.Balance);
                Assert.Equal(1000, r.LocalValue);
                Assert.Equal(500, r.ForeignBalance);
                Assert.Equal(500, r.ForeignValue);
                Assert.False(r.IsCreditWip);
            }

            [Fact]
            public async Task ShouldGetProfitCenterDataUsingStaff()
            {
                var fixture = new WipAdjustmentsFixture(Db);

                var country = new CountryBuilder { Id = "YY" }.Build().In(Db);
                var name = new NameBuilder(Db) { UsedAs = NameUsedAs.Individual, Nationality = country, Remarks = Fixture.String(), TaxNumber = Fixture.String() }.WithFamily().Build().In(Db);
                var profitCenter = new ProfitCentre("123", Fixture.String()).In(Db);
                new Employee { Id = name.Id, ProfitCentre = profitCenter.Id }.In(Db);

                var r = await fixture.Subject.GetStaffProfitCenter(name.Id, _culture);

                Assert.Equal(profitCenter.Id, r.Code);
                Assert.Equal(profitCenter.Name, r.Description);
            }
        }

        public class AdjustItemsMethod : FactBase
        {
            readonly int _entityKey = Fixture.Integer();
            readonly int _identityId = Fixture.Integer();
            readonly int _newTransKey = Fixture.Integer();
            readonly int _transKey = Fixture.Integer();
            readonly short _wipSeqKey = Fixture.Short();

            [Fact]
            public async Task ShouldValidateTransactionDate()
            {
                var adjustWipItem = new AdjustWipItemDto
                {
                    EntityKey = _entityKey,
                    TransKey = _transKey,
                    WIPSeqKey = _wipSeqKey,
                    TransDate = Fixture.Today(),
                    LogDateTimeStamp = Fixture.PastDate()
                };

                var changeSetEntries = new[]
                {
                    new ChangeSetEntry<AdjustWipItemDto>
                    {
                        Entity = adjustWipItem
                    }
                };

                var fixture = new WipAdjustmentsFixture(Db)
                              .WithValidPostDate()
                              .WithWipAdjusted(adjustWipItem, _newTransKey);

                await fixture.Subject.AdjustItems(_identityId, "en", changeSetEntries);

                Assert.Equal(_newTransKey, adjustWipItem.NewTransKey);
                Assert.Null(changeSetEntries.Single().ValidationErrors);

                fixture.ValidatePostDates.Received(1).For(Fixture.Today(), Arg.Any<SystemIdentifier>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnValidationErrorIfTransactionDateIsInvalid()
            {
                var adjustWipItem = new AdjustWipItemDto
                {
                    EntityKey = _entityKey,
                    TransKey = _transKey,
                    WIPSeqKey = _wipSeqKey,
                    TransDate = Fixture.Today(),
                    LogDateTimeStamp = Fixture.PastDate()
                };

                var changeSetEntries = new[]
                {
                    new ChangeSetEntry<AdjustWipItemDto>
                    {
                        Entity = adjustWipItem
                    }
                };

                var fixture = new WipAdjustmentsFixture(Db)
                    .WithInvalidPostDate("AC126", false);

                await fixture.Subject.AdjustItems(_identityId, "en", changeSetEntries);

                Assert.Null(adjustWipItem.NewTransKey);
                Assert.NotEmpty(changeSetEntries.Single().ValidationErrors);
            }

            [Theory]
            [InlineData(TransactionType.DebtorWipTransfer, 123, null, null, null)]
            [InlineData(TransactionType.CaseWipTransfer, null, 456, null, null)]
            [InlineData(TransactionType.StaffWipTransfer, null, null, 789, null)]
            [InlineData(TransactionType.ProductWipTransfer, null, null, null, 666)]
            public async Task ShouldTransferDiscountWithAmendedDetailsBasedOnTransferType(int adjustmentType,
                                                                                          int? acctClientKey, int? caseKey, int? staffKey, int? productKey)
            {
                new WorkInProgress
                {
                    EntityId = _entityKey,
                    TransactionId = _transKey,
                    WipSequenceNo = _wipSeqKey,
                    IsDiscount = 0,
                    IsMargin = false
                }.In(Db);

                var discountWip = new WorkInProgress
                {
                    EntityId = _entityKey,
                    TransactionId = _transKey,
                    WipSequenceNo = (short)(_wipSeqKey - 1),
                    IsDiscount = 1,
                    Status = TransactionStatus.Active,
                    NarrativeId = Fixture.Short(),
                    ShortNarrative = Fixture.String()
                }.In(Db);

                var changeSetEntries = new AdjustWipItemDto
                {
                    EntityKey = _entityKey,
                    TransKey = _transKey,
                    WIPSeqKey = _wipSeqKey,
                    TransDate = Fixture.Today(),
                    LogDateTimeStamp = Fixture.PastDate(),
                    AdjustDiscount = true,
                    ReasonCode = Fixture.String(),
                    RequestedByStaffKey = Fixture.Integer(),
                    NewAcctClientKey = acctClientKey,
                    NewStaffKey = staffKey,
                    NewCaseKey = caseKey,
                    NewProductKey = productKey,
                    AdjustmentType = adjustmentType
                }.AsChangeSetEntries(out var adjustWipItem);

                var fixture = new WipAdjustmentsFixture(Db)
                              .WithValidPostDate()
                              .WithWipAdjusted(adjustWipItem, _newTransKey);

                await fixture.Subject.AdjustItems(_identityId, "en", changeSetEntries);

                Assert.NotNull(adjustWipItem.NewTransKey);

                // one call for the request adjustment wip item
                fixture.AdjustWipCommand
                       .Received(1)
                       .SaveAdjustment(_identityId,
                                       Arg.Any<string>(),
                                       Arg.Is<AdjustWipItemDto>(_ => _.WipSeqNo == _wipSeqKey), false).IgnoreAwaitForNSubstituteAssertion();

                // one call for its associated discount
                fixture.AdjustWipCommand
                       .Received(1)
                       .SaveAdjustment(_identityId,
                                       Arg.Any<string>(),
                                       Arg.Is<AdjustWipItem>(_ => _.WipSeqNo == discountWip.WipSequenceNo &&
                                                                  _.NewNarrativeKey == discountWip.NarrativeId &&
                                                                  _.NewDebitNoteText == discountWip.ShortNarrative &&
                                                                  _.NewTransKey == adjustWipItem.NewTransKey &&
                                                                  _.TransDate == adjustWipItem.TransDate &&
                                                                  _.ReasonCode == adjustWipItem.ReasonCode &&
                                                                  _.RequestedByStaffKey == adjustWipItem.RequestedByStaffKey &&
                                                                  _.AdjustmentType == adjustWipItem.AdjustmentType &&
                                                                  _.NewAcctClientKey == adjustWipItem.NewAcctClientKey &&
                                                                  _.NewCaseKey == adjustWipItem.NewCaseKey &&
                                                                  _.NewStaffKey == adjustWipItem.NewStaffKey &&
                                                                  _.NewProductKey == adjustWipItem.NewProductKey), false)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class SplitItemsMethod : FactBase
        {
            readonly int _entityKey = Fixture.Integer();
            readonly int _identityId = Fixture.Integer();
            readonly int _newTransKey = Fixture.Integer();
            readonly int _transKey = Fixture.Integer();
            readonly short _wipSeqKey = Fixture.Short();

            [Theory]
            [InlineData(false, 1000, 1250, 1000, 1250, 2000, 2500, 2000, 2500)]
            [InlineData(true, 1000, 1250, -1000, -1250, 2000, 2500, -2000, -2500)]
            public async Task ShouldSaveTheSplitsAccordingly(
                bool isCreditWip,
                decimal split1LocalAmount, decimal split1ForeignAmount, decimal split1ExpectedLocalAmount, decimal split1ExpectedForeignAmount,
                decimal split2LocalAmount, decimal split2ForeignAmount, decimal split2ExpectedLocalAmount, decimal split2ExpectedForeignAmount)
            {
                var changeSetEntries = new[]
                {
                    new SplitWipItem
                    {
                        EntityKey = _entityKey,
                        TransKey = _transKey,
                        WipSeqKey = _wipSeqKey,
                        TransDate = Fixture.Today(),
                        LogDateTimeStamp = Fixture.PastDate(),
                        IsCreditWip = isCreditWip,
                        LocalAmount = split1LocalAmount,
                        ForeignAmount = split1ForeignAmount
                    },
                    new SplitWipItem
                    {
                        EntityKey = _entityKey,
                        TransKey = _transKey,
                        WipSeqKey = _wipSeqKey,
                        TransDate = Fixture.Today(),
                        LogDateTimeStamp = Fixture.PastDate(),
                        IsCreditWip = isCreditWip,
                        LocalAmount = split2LocalAmount,
                        ForeignAmount = split2ForeignAmount
                    }
                }.AsChangeSetEntries(out var split1, out var split2);

                var firstWipSeqKey = Fixture.Short();
                var secondWipSeqKey = Fixture.Short();

                var fixture = new WipAdjustmentsFixture(Db)
                              .WithValidPostDate()
                              .WithWipSplit(split1, _newTransKey, firstWipSeqKey)
                              .WithWipSplit(split2, _newTransKey, secondWipSeqKey);

                await fixture.Subject.SplitItems(_identityId, "en", changeSetEntries);

                Assert.Equal(_newTransKey, split1.NewTransKey);
                Assert.Equal(firstWipSeqKey, split1.NewWipSeqKey);
                Assert.Equal(split1ExpectedLocalAmount, split1.LocalAmount);
                Assert.Equal(split1ExpectedForeignAmount, split1.ForeignAmount);
                Assert.Null(changeSetEntries.ElementAt(0).ValidationErrors);
                Assert.False(split1.IsLastSplit);

                Assert.Equal(_newTransKey, split2.NewTransKey);
                Assert.Equal(secondWipSeqKey, split2.NewWipSeqKey);
                Assert.Equal(split2ExpectedLocalAmount, split2.LocalAmount);
                Assert.Equal(split2ExpectedForeignAmount, split2.ForeignAmount);
                Assert.Null(changeSetEntries.ElementAt(1).ValidationErrors);
                Assert.True(split2.IsLastSplit);

                fixture.ValidatePostDates.Received(2).For(Fixture.Today(), Arg.Any<SystemIdentifier>())
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.SplitWipCommand.Received(1).Split(_identityId, Arg.Any<string>(), split1).IgnoreAwaitForNSubstituteAssertion();
                fixture.SplitWipCommand.Received(1).Split(_identityId, Arg.Any<string>(), split2).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnValidationErrorIfTransactionDateIsInvalid()
            {
                var changeSetEntries = new[]
                {
                    new SplitWipItem
                    {
                        EntityKey = _entityKey,
                        TransKey = _transKey,
                        WipSeqKey = _wipSeqKey,
                        TransDate = Fixture.Today(),
                        LogDateTimeStamp = Fixture.PastDate()
                    },
                    new SplitWipItem
                    {
                        EntityKey = _entityKey,
                        TransKey = _transKey,
                        WipSeqKey = _wipSeqKey,
                        TransDate = Fixture.Today(),
                        LogDateTimeStamp = Fixture.PastDate()
                    }
                }.AsChangeSetEntries(out var split1, out var split2);

                var fixture = new WipAdjustmentsFixture(Db)
                    .WithInvalidPostDate("AC126", false);

                await fixture.Subject.SplitItems(_identityId, "en", changeSetEntries);

                Assert.Null(split1.NewTransKey);
                Assert.Null(split2.NewTransKey);
                Assert.NotEmpty(changeSetEntries.ElementAt(0).ValidationErrors); /* stops at first validation error */
                Assert.Null(changeSetEntries.ElementAt(1).ValidationErrors);
            }
        }
    }

    public static class TestEx
    {
        public static ChangeSetEntry<T>[] AsChangeSetEntries<T>(this T entity, out T theEntity)
        {
            theEntity = entity;

            return new[]
            {
                new ChangeSetEntry<T>
                {
                    Entity = entity
                }
            };
        }

        public static ChangeSetEntry<T>[] AsChangeSetEntries<T>(this IEnumerable<T> entities, out T theEntity1, out T theEntity2)
        {
            var entitiesArray = entities.ToArray();

            theEntity1 = entitiesArray.ElementAtOrDefault(0);
            theEntity2 = entitiesArray.ElementAtOrDefault(1);

            return entitiesArray.Select(_ => new ChangeSetEntry<T> { Entity = _ }).ToArray();
        }
    }
}