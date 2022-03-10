using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class ChangeAlertPersistenceFacts
    {
        readonly IChangeAlertGeneratorCommands _changeAlertGeneratorCommands = Substitute.For<IChangeAlertGeneratorCommands>();
        readonly ILogger<ChangeAlertPersistence> _logger = Substitute.For<ILogger<ChangeAlertPersistence>>();

        ChangeAlertPersistence CreateSubject()
        {
            return new ChangeAlertPersistence(_changeAlertGeneratorCommands, _logger);
        }

        [Fact]
        public async Task ShouldGenerateChangeAlertForDebtorIfDebtorHasBeenOverriden()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var requestId = Guid.NewGuid();
            var result = new SaveOpenItemResult(requestId);

            var model = new OpenItemModel
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                Debtors = new List<DebtorData>
                {
                    new()
                    {
                        NameId = Fixture.Integer(),
                        IsOverriddenDebtor = true
                    }
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            _changeAlertGeneratorCommands
                .Received(1)
                .Generate(userIdentityId, culture, (int)model.ItemEntityId, (int)model.ItemTransactionId,
                          model.Debtors.Single().NameId,
                          hasDebtorChanged: true,
                          hasDebtorReferenceChanged: false,
                          hasAddressChanged: false,
                          hasAttentionChanged: false,
                          addressChangeReasonId: null)
                .IgnoreAwaitForNSubstituteAssertion();

            _logger.Received().Trace(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldGenerateChangeAlertForDebtorIfAddressHasChanged()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var requestId = Guid.NewGuid();
            var addressChangeReason = Fixture.Integer();
            var result = new SaveOpenItemResult(requestId);

            var model = new OpenItemModel
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                Debtors = new List<DebtorData>
                {
                    new()
                    {
                        NameId = Fixture.Integer(),
                        AddressChangeReasonId = addressChangeReason,
                        HasAddressChanged = true
                    }
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            _changeAlertGeneratorCommands
                .Received(1)
                .Generate(userIdentityId, culture, (int)model.ItemEntityId, (int)model.ItemTransactionId,
                          model.Debtors.Single().NameId,
                          hasDebtorChanged: false,
                          hasDebtorReferenceChanged: false,
                          hasAddressChanged: true,
                          hasAttentionChanged: false,
                          addressChangeReasonId: addressChangeReason)
                .IgnoreAwaitForNSubstituteAssertion();

            _logger.Received().Trace(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldGenerateChangeAlertForDebtorIfAttentionNameHasChanged()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var requestId = Guid.NewGuid();
            var addressChangeReason = Fixture.Integer();
            var result = new SaveOpenItemResult(requestId);

            var model = new OpenItemModel
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                Debtors = new[]
                {
                    new DebtorData
                    {
                        NameId = Fixture.Integer(),
                        AddressChangeReasonId = addressChangeReason,
                        HasAttentionNameChanged = true
                    }
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            _changeAlertGeneratorCommands
                .Received(1)
                .Generate(userIdentityId, culture, (int)model.ItemEntityId, (int)model.ItemTransactionId,
                          model.Debtors.Single().NameId,
                          hasDebtorChanged: false,
                          hasDebtorReferenceChanged: false,
                          hasAddressChanged: false,
                          hasAttentionChanged: true,
                          addressChangeReasonId: addressChangeReason)
                .IgnoreAwaitForNSubstituteAssertion();

            _logger.Received().Trace(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldGenerateChangeAlertForDebtorIfReferenceNoHasChanged()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var requestId = Guid.NewGuid();
            var addressChangeReason = Fixture.Integer();
            var result = new SaveOpenItemResult(requestId);

            var model = new OpenItemModel
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                Debtors = new[]
                {
                    new DebtorData
                    {
                        NameId = Fixture.Integer(),
                        AddressChangeReasonId = addressChangeReason,
                        HasReferenceNoChanged = true
                    }
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            _changeAlertGeneratorCommands
                .Received(1)
                .Generate(userIdentityId, culture, (int)model.ItemEntityId, (int)model.ItemTransactionId,
                          model.Debtors.Single().NameId,
                          hasDebtorChanged: false,
                          hasDebtorReferenceChanged: true,
                          hasAddressChanged: false,
                          hasAttentionChanged: false,
                          addressChangeReasonId: addressChangeReason)
                .IgnoreAwaitForNSubstituteAssertion();

            _logger.Received().Trace(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldGenerateChangeAlertForDebtorIfCopiesToHasAddressChanged()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var requestId = Guid.NewGuid();
            var debtorId = Fixture.Integer();
            var copiesToNameId = Fixture.Integer();
            var addressChangeReason = Fixture.Integer();
            var result = new SaveOpenItemResult(requestId);

            var model = new OpenItemModel
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                Debtors = new[]
                {
                    new DebtorData
                    {
                        NameId = debtorId,
                        HasCopyToDataChanged = true,
                        CopiesTos = new[]
                        {
                            new DebtorCopiesTo
                            {
                                DebtorNameId = debtorId,
                                CopyToNameId = copiesToNameId,
                                AddressChangeReasonId = addressChangeReason,
                                HasAddressChanged = true
                            }
                        }
                    }
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            _changeAlertGeneratorCommands
                .Received(1)
                .Generate(userIdentityId, culture, (int)model.ItemEntityId, (int)model.ItemTransactionId,
                          debtorId,
                          copiesToNameId,
                          false,
                          hasAddressChanged: true,
                          hasAttentionChanged: false,
                          addressChangeReasonId: addressChangeReason)
                .IgnoreAwaitForNSubstituteAssertion();

            _logger.Received().Trace(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldGenerateChangeAlertForDebtorIfCopiesToHasAttentionChanged()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var requestId = Guid.NewGuid();
            var debtorId = Fixture.Integer();
            var copiesToNameId = Fixture.Integer();
            var addressChangeReason = Fixture.Integer();
            var result = new SaveOpenItemResult(requestId);

            var model = new OpenItemModel
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                Debtors = new[]
                {
                    new DebtorData
                    {
                        NameId = debtorId,
                        HasCopyToDataChanged = true,
                        CopiesTos = new[]
                        {
                            new DebtorCopiesTo
                            {
                                DebtorNameId = debtorId,
                                CopyToNameId = copiesToNameId,
                                AddressChangeReasonId = addressChangeReason,
                                HasAttentionChanged = true
                            }
                        }
                    }
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            _changeAlertGeneratorCommands
                .Received(1)
                .Generate(userIdentityId, culture, (int)model.ItemEntityId, (int)model.ItemTransactionId,
                          debtorId,
                          copiesToNameId,
                          false,
                          hasAddressChanged: false,
                          hasAttentionChanged: true,
                          addressChangeReasonId: addressChangeReason)
                .IgnoreAwaitForNSubstituteAssertion();

            _logger.Received().Trace(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldGenerateChangeAlertForEveryModifiedItems()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var requestId = Guid.NewGuid();
            var result = new SaveOpenItemResult(requestId);

            var model = new OpenItemModel
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                ModifiedItems = new List<ModifiedItem>
                {
                    new()
                    {
                        ChangedItem = Fixture.String(),
                        OldValue = Fixture.String(),
                        NewValue = Fixture.String(),
                        ReasonCode = Fixture.String(),
                        CaseId = Fixture.Integer()
                    }
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            _changeAlertGeneratorCommands
                .Received(1)
                .Generate(userIdentityId, culture, (int)model.ItemEntityId, (int)model.ItemTransactionId,
                          model.ModifiedItems.Single().ChangedItem,
                          model.ModifiedItems.Single().OldValue,
                          model.ModifiedItems.Single().NewValue,
                          model.ModifiedItems.Single().CaseId,
                          model.ModifiedItems.Single().ReasonCode)
                .IgnoreAwaitForNSubstituteAssertion();

            _logger.Received().Trace(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldGenerateChangeAlertForEveryModifiedItemsFallsBackToMainCase()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var requestId = Guid.NewGuid();
            var result = new SaveOpenItemResult(requestId);

            var model = new OpenItemModel
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                MainCaseId = Fixture.Integer(),
                ModifiedItems = new[]
                {
                    new ModifiedItem
                    {
                        ChangedItem = Fixture.String(),
                        OldValue = Fixture.String(),
                        NewValue = Fixture.String(),
                        ReasonCode = Fixture.String()
                    }
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            _changeAlertGeneratorCommands
                .Received(1)
                .Generate(userIdentityId, culture, (int)model.ItemEntityId, (int)model.ItemTransactionId,
                          model.ModifiedItems.Single().ChangedItem,
                          model.ModifiedItems.Single().OldValue,
                          model.ModifiedItems.Single().NewValue,
                          model.MainCaseId,
                          model.ModifiedItems.Single().ReasonCode)
                .IgnoreAwaitForNSubstituteAssertion();

            _logger.Received().Trace(Arg.Any<string>());
        }
    }
}