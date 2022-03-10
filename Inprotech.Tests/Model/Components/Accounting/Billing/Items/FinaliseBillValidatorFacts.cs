using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items
{

    public class FinaliseBillValidatorFacts : FactBase
    {
        readonly int _userIdentityId = Fixture.Integer();
        readonly string _culture = Fixture.String();
        readonly Guid _requestId = Guid.NewGuid();
        
        dynamic CreateOpenItemWithCase(int? itemEntityId = null, int? itemTransactionId = null, ItemType itemType = ItemType.DebitNote, TransactionStatus? openItemStatus = null, Case caseInput = null)
        {
            itemEntityId ??= Fixture.Integer();
            itemTransactionId ??= Fixture.Integer();
            var openItemNo = Fixture.String();

            var @case = caseInput ?? new CaseBuilder().Build().In(Db);

            var wip = new WorkInProgress
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSequenceNo = Fixture.Short(),
                CaseId = @case.Id
            }.In(Db);

            new BilledItem
            {
                EntityId = itemEntityId.Value,
                TransactionId = itemTransactionId.Value,
                WipEntityId = wip.EntityId,
                WipTransactionId = wip.TransactionId,
                WipSequenceNo = wip.WipSequenceNo
            }.In(Db);

            var openItem = new OpenItemBuilder(Db)
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                TypeId = itemType,
                Status = openItemStatus ?? TransactionStatus.Draft,
                OpenItemNo = openItemNo
            }.Build().In(Db);

            return new
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = openItemNo,
                OpenItem = openItem,
                Case = @case
            };
        }

        FinaliseBillValidator CreateSubject(Warn warn = null, params int[] caseIdsWithRestrictions)
        {
            warn ??= new Warn();
            var settingsResolver = Substitute.For<IBillingSiteSettingsResolver>();
            settingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                            .Returns(new BillingSiteSettings
                            {
                                ShouldWarnIfUnpostedTimeExistOnBillFinalisation = warn.IfUnpostedTimeExistOnBillFinalisation,
                                ShouldWarnIfDraftBillForSameCaseExistOnBillFinalisation = warn.IfDraftBillForSameCaseExistOnBillFinalisation,
                                ShouldWarnIfNonIncludedDebitWipExistOnBillFinalisation = warn.IfNonIncludedDebitWipExistOnBillFinalisation
                            });

            var logger = Substitute.For<ILogger<FinaliseBillValidator>>();

            var wipItemsService = Substitute.For<IWipItemsService>();
            wipItemsService.GetAvailableWipItems(_userIdentityId, _culture, Arg.Any<WipSelectionCriteria>())
                            .Returns(Enumerable.Empty<AvailableWipItem>());

            var caseStatusValidator = Substitute.For<ICaseStatusValidator>();
            caseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                               .Returns(Db.Set<Case>().Where(_ => caseIdsWithRestrictions.Contains(_.Id)));
            
            return new FinaliseBillValidator(Db, logger, wipItemsService, caseStatusValidator, settingsResolver);
        }

        [Fact]
        public async Task ShouldSeekConfirmationWhenThereAreRelatedBills()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var multiDebtorBillForDebtor1 = CreateOpenItemWithCase(itemEntityId, itemTransactionId);
            var multiDebtorBillForDebtor2 = CreateOpenItemWithCase(itemEntityId, itemTransactionId);

            multiDebtorBillForDebtor1.OpenItem.BillPercentage = 70;
            multiDebtorBillForDebtor2.OpenItem.BillPercentage = 30;

            var subject = CreateSubject();

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = multiDebtorBillForDebtor1.OpenItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC119", r.ErrorCode);
            Assert.Equal(itemEntityId, r.EntityId);
            Assert.Equal(itemTransactionId, r.TransactionId);
            Assert.Equal(multiDebtorBillForDebtor1.OpenItemNo, r.OpenItemNo);
            Assert.True(r.IsConfirmationRequired);
            Assert.Equal(multiDebtorBillForDebtor2.OpenItemNo, r.BillsImpacted.Single());
        }

        [Fact]
        public async Task ShouldReturnErrorWhenTheBillCouldNotBeFoundBasedOnDraftOpenItemNumber()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var openItemNo = "D123";

            var bill = CreateOpenItemWithCase(itemEntityId, itemTransactionId);
            
            bill.OpenItem.OpenItemNo = "123"; /* finalised bill changes the OpenItemNo */
            bill.OpenItem.Status = TransactionStatus.Active;
            
            var subject = CreateSubject();

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = openItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC136", r.ErrorCode);
            Assert.Equal(itemEntityId, r.EntityId);
            Assert.Equal(itemTransactionId, r.TransactionId);
            Assert.Equal(openItemNo, r.OpenItemNo);
            Assert.True(r.IsError);
        }

        [Fact]
        public async Task ShouldReturnErrorWhenTheBillCouldNotBeFound()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            CreateOpenItemWithCase(itemEntityId, itemTransactionId);
            
            var subject = CreateSubject();

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = "D123"
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC136", r.ErrorCode);
            Assert.Equal(itemEntityId, r.EntityId);
            Assert.Equal(itemTransactionId, r.TransactionId);
            Assert.True(r.IsError);
        }

        [Fact]
        public async Task ShouldReturnErrorWhenTheBillIsAlreadyFinalised()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var bill = CreateOpenItemWithCase(itemEntityId, itemTransactionId, openItemStatus: TransactionStatus.Active);
            
            var subject = CreateSubject();

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = bill.OpenItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC125", r.ErrorCode);
            Assert.Equal(itemEntityId, r.EntityId);
            Assert.Equal(itemTransactionId, r.TransactionId);
            Assert.Equal(bill.OpenItemNo, r.OpenItemNo);
            Assert.True(r.IsError);
        }
        
        [Fact]
        public async Task ShouldReturnErrorWhenTheBillWhenAnotherUserIsMaintainingIt()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var bill = CreateOpenItemWithCase(itemEntityId, itemTransactionId);

            bill.OpenItem.LockIdentityId = Fixture.Integer(); /* someone other than _userIdentityId */
            
            var subject = CreateSubject();

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = bill.OpenItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC120", r.ErrorCode);
            Assert.Equal(itemEntityId, r.EntityId);
            Assert.Equal(itemTransactionId, r.TransactionId);
            Assert.Equal(bill.OpenItemNo, r.OpenItemNo);
            Assert.True(r.IsError);
        }
        
        [Theory]
        [InlineData(ItemType.CreditJournal)]
        [InlineData(ItemType.DebitJournal)]
        [InlineData(ItemType.Prepayment)]
        [InlineData(ItemType.UnallocatedCash)]
        [InlineData(ItemType.Unknown)]
        public async Task ShouldReturnErrorWhenBillIsNotDebitNotesOrCreditNotes(ItemType illegalItemTypeForFinalisation)
        {
            var data = CreateOpenItemWithCase(itemType: illegalItemTypeForFinalisation);
            
            var subject = CreateSubject(new Warn
            {
                IfUnpostedTimeExistOnBillFinalisation = true
            });

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = data.ItemEntityId,
                ItemTransactionId = data.ItemTransactionId,
                OpenItemNo = data.OpenItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC139", r.ErrorCode);
            Assert.Equal(data.ItemEntityId, r.EntityId);
            Assert.Equal(data.ItemTransactionId, r.TransactionId);
            Assert.Equal(data.OpenItemNo, r.OpenItemNo);
            Assert.True(r.IsError);
        }

        [Theory]
        [InlineData(ItemType.DebitNote)]
        [InlineData(ItemType.InternalDebitNote)]
        [InlineData(ItemType.CreditNote)]
        [InlineData(ItemType.InternalCreditNote)]
        public async Task ShouldNotReturnValidationSummaryWhenDebitNotesOrCreditNotesAreBeingFinalised(ItemType allowedItemType)
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var openItemNo = Fixture.String();

            new OpenItemBuilder(Db)
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = openItemNo,
                TypeId = allowedItemType,
                Status = TransactionStatus.Draft
            }.Build().In(Db);

            var subject = CreateSubject();

            var r = await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = openItemNo
            });

            Assert.Empty(r);
        }

        [Fact]
        public async Task ShouldReturnErrorWhenTheBillHasAppliedCreditsThatIsLocked()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var other = CreateOpenItemWithCase();
            var bill = CreateOpenItemWithCase(itemEntityId, itemTransactionId);
            
            new BilledCredit
            {
                DebitItemEntityId = itemEntityId,
                DebitItemTransactionId = itemTransactionId,
                CreditItemEntityId = other.OpenItem.ItemEntityId,
                CreditItemTransactionId = other.OpenItem.ItemTransactionId,
                CreditAccountEntityId = other.OpenItem.AccountEntityId,
                CreditAccountDebtorId = other.OpenItem.AccountDebtorId
            }.In(Db);

            other.OpenItem.LockIdentityId = Fixture.Integer(); /* someone other than _userIdentityId */
            
            var subject = CreateSubject();

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = bill.OpenItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC221", r.ErrorCode);
            Assert.Equal(itemEntityId, r.EntityId);
            Assert.Equal(itemTransactionId, r.TransactionId);
            Assert.Equal(other.OpenItem.ItemDate, r.ItemDate);
            Assert.True(r.IsError);
        }
        
        [Fact]
        public async Task ShouldReturnErrorWhenTheBillHasCasesWithStatusRestrictedForBilling()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            var bill = CreateOpenItemWithCase(itemEntityId, itemTransactionId);
            
            var subject = CreateSubject(caseIdsWithRestrictions: bill.Case.Id);

            var r1 = await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = bill.OpenItemNo
            });

            var r = ((IEnumerable<FinaliseValidationSummary>)r1).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("BI33", r.ErrorCode);
            Assert.Equal(itemEntityId, r.EntityId);
            Assert.Equal(itemTransactionId, r.TransactionId);
            Assert.Equal(bill.Case.Id, r.CasesImpacted.Single().CaseId);
            Assert.True(r.IsError);
        }

        [Fact]
        public async Task ShouldNotReturnValidationSummaryWhenNotIndicatedToValidateUnpostedTime()
        {
            var data = CreateOpenItemWithCase();

            new DiaryBuilder(Db)
            {
                IsTimer = false,
                EntityId = null,
                TransNo = null,
                Case = data.Case,
                TimeValue = Fixture.Integer()
            }.Build().In(Db);

            var subject = CreateSubject(new Warn
            {
                IfUnpostedTimeExistOnBillFinalisation = false
            });

            var r = await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = data.ItemEntityId,
                ItemTransactionId = data.ItemTransactionId,
                OpenItemNo = data.OpenItemNo
            });

            Assert.Empty(r);
        }

        [Fact]
        public async Task ShouldSeekConfirmationWhenIndicatedToValidateUnpostedTimeAndThoseCasesExist()
        {
            var data = CreateOpenItemWithCase();

            new DiaryBuilder(Db)
            {
                IsTimer = false,
                EntityId = null,
                TransNo = null,
                Case = data.Case,
                TimeValue = Fixture.Integer()
            }.BuildWithCase(true).In(Db);

            var subject = CreateSubject(new Warn
            {
                IfUnpostedTimeExistOnBillFinalisation = true
            });

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = data.ItemEntityId,
                ItemTransactionId = data.ItemTransactionId,
                OpenItemNo = data.OpenItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC123", r.ErrorCode);
            Assert.Equal(data.ItemEntityId, r.EntityId);
            Assert.Equal(data.ItemTransactionId, r.TransactionId);
            Assert.Equal(data.OpenItemNo, r.OpenItemNo);
            Assert.True(r.IsConfirmationRequired);
            Assert.Equal(data.Case.Id, r.CasesImpacted.Single().CaseId);
            Assert.Equal(data.Case.Irn, r.CasesImpacted.Single().CaseReference);
        }

        [Fact]
        public async Task ShouldNotReturnValidationSummaryWhenNotIndicatedToValidateBillCasesThatExistsInOtherDraftBills()
        {
            var openItemToFinalise = CreateOpenItemWithCase();

            CreateOpenItemWithCase(
                                   openItemStatus: TransactionStatus.Draft,
                                   caseInput: openItemToFinalise.Case);

            var subject = CreateSubject(new Warn
            {
                IfDraftBillForSameCaseExistOnBillFinalisation = false
            });

            var r = await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = openItemToFinalise.ItemEntityId,
                ItemTransactionId = openItemToFinalise.ItemTransactionId,
                OpenItemNo = openItemToFinalise.OpenItemNo
            });

            Assert.Empty(r);
        }

        [Fact]
        public async Task ShouldSeekConfirmationWhenIndicatedToValidateBillCasesThatExistsInOtherDraftBillsAndThoseBillsExist()
        {
            var openItemToFinalise = CreateOpenItemWithCase();

            var otherOpenItem = CreateOpenItemWithCase(
                                                       openItemStatus: TransactionStatus.Draft,
                                                       caseInput: openItemToFinalise.Case);

            var subject = CreateSubject(new Warn
            {
                IfDraftBillForSameCaseExistOnBillFinalisation = true
            });

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = openItemToFinalise.ItemEntityId,
                ItemTransactionId = openItemToFinalise.ItemTransactionId,
                OpenItemNo = openItemToFinalise.OpenItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC121", r.ErrorCode);
            Assert.Equal(openItemToFinalise.ItemEntityId, r.EntityId);
            Assert.Equal(openItemToFinalise.ItemTransactionId, r.TransactionId);
            Assert.Equal(openItemToFinalise.OpenItemNo, r.OpenItemNo);
            Assert.True(r.IsConfirmationRequired);
            Assert.Contains(otherOpenItem.OpenItemNo, r.BillsImpacted);
        }

        [Fact]
        public async Task ShouldNotReturnValidationSummaryWhenNotIndicatedToValidateDebitWipNotIncludedInBill()
        {
            var openItemToFinalise = CreateOpenItemWithCase();

            new WorkInProgress
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSequenceNo = Fixture.Short(),
                CaseId = openItemToFinalise.Case.Id,
                LocalValue = 100,
                Status = TransactionStatus.Active
            }.In(Db);

            var subject = CreateSubject(new Warn
            {
                IfNonIncludedDebitWipExistOnBillFinalisation = false
            });

            var r = await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = openItemToFinalise.ItemEntityId,
                ItemTransactionId = openItemToFinalise.ItemTransactionId,
                OpenItemNo = openItemToFinalise.OpenItemNo
            });

            Assert.Empty(r);
        }

        [Fact]
        public async Task ShouldSeekConfirmationWhenIndicatedToValidateDebitWipNotIncludedInBill()
        {
            var openItemToFinalise = CreateOpenItemWithCase();

            new WorkInProgress
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSequenceNo = Fixture.Short(),
                CaseId = openItemToFinalise.Case.Id,
                LocalValue = 100,
                Status = TransactionStatus.Active
            }.In(Db);

            var subject = CreateSubject(new Warn
            {
                IfNonIncludedDebitWipExistOnBillFinalisation = true
            });

            var r = (await subject.Validate(_userIdentityId, _culture, _requestId, new FinaliseRequest
            {
                ItemEntityId = openItemToFinalise.ItemEntityId,
                ItemTransactionId = openItemToFinalise.ItemTransactionId,
                OpenItemNo = openItemToFinalise.OpenItemNo
            })).SingleOrDefault();

            Assert.NotNull(r);
            Assert.Equal("AC122", r.ErrorCode);
            Assert.Equal(openItemToFinalise.ItemEntityId, r.EntityId);
            Assert.Equal(openItemToFinalise.ItemTransactionId, r.TransactionId);
            Assert.Equal(openItemToFinalise.OpenItemNo, r.OpenItemNo);
            Assert.True(r.IsConfirmationRequired);
            Assert.Equal(openItemToFinalise.Case.Id, r.CasesImpacted.Single().CaseId);
            Assert.Equal(openItemToFinalise.Case.Irn, r.CasesImpacted.Single().CaseReference);
        }

        class Warn
        {
            public bool IfUnpostedTimeExistOnBillFinalisation { get; set; }
            public bool IfNonIncludedDebitWipExistOnBillFinalisation { get; set; }
            public bool IfDraftBillForSameCaseExistOnBillFinalisation { get; set; }
        }
    }
}