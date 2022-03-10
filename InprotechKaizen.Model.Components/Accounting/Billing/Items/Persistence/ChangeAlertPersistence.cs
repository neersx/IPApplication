using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class ChangeAlertPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IChangeAlertGeneratorCommands _changeAlertGenerator;
        readonly ILogger<ChangeAlertPersistence> _logger;

        public ChangeAlertPersistence(IChangeAlertGeneratorCommands changeAlertGenerator, ILogger<ChangeAlertPersistence> logger)
        {
            _changeAlertGenerator = changeAlertGenerator;
            _logger = logger;
        }

        public Stage Stage => Stage.GenerateChangeAlert;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null || model.ItemTransactionId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)} and {nameof(model.ItemTransactionId)} must both have a value.");
            }

            foreach (var debtor in model.Debtors)
            {
                if (!IsReminderRequired(debtor)) continue;

                await GenerateChangeAlertsForDebtor(userIdentityId, culture,
                                                    (int)model.ItemEntityId, (int)model.ItemTransactionId,
                                                    debtor);

                foreach (var copiesTo in debtor.CopiesTos)
                {
                    if (!IsReminderRequired(copiesTo)) continue;

                    await GenerateChangeAlertsForDebtorCopiesTo(userIdentityId, culture,
                                                                (int)model.ItemEntityId, (int)model.ItemTransactionId,
                                                                copiesTo);
                }
            }

            foreach (var modifiedItem in model.ModifiedItems)
            {
                await GenerateChangeAlertForModifiedItem(userIdentityId, culture,
                                                         (int)model.ItemEntityId, (int)model.ItemTransactionId, model.MainCaseId,
                                                         modifiedItem);
            }

            return true;
        }

        async Task GenerateChangeAlertForModifiedItem(int userIdentityId, string culture, int itemEntityId, int itemTransactionId, int? mainCaseId, ModifiedItem modifiedItem)
        {
            _logger.Trace($"{nameof(GenerateChangeAlertForModifiedItem)} {modifiedItem.ChangedItem}/{modifiedItem.OldValue}=>{modifiedItem.NewValue}/{modifiedItem.CaseId ?? mainCaseId}/{modifiedItem.ReasonCode}");

            await _changeAlertGenerator.Generate(userIdentityId, culture,
                                                 itemEntityId,
                                                 itemTransactionId,
                                                 modifiedItem.ChangedItem,
                                                 modifiedItem.OldValue,
                                                 modifiedItem.NewValue,
                                                 modifiedItem.CaseId ?? mainCaseId,
                                                 modifiedItem.ReasonCode);
        }

        async Task GenerateChangeAlertsForDebtor(int userIdentityId, string culture, int itemEntityId, int itemTransactionId, DebtorData debtor)
        {
            var changed = new List<string>(new[] { $"{debtor.NameId}" });
            if (debtor.IsOverriddenDebtor) changed.Add("Debtor");
            if (debtor.HasReferenceNoChanged) changed.Add("ReferenceNo");
            if (debtor.HasAddressChanged) changed.Add($"Address (reason={debtor.AddressChangeReasonId})");
            if (debtor.HasAttentionNameChanged) changed.Add("Attention");

            _logger.Trace($"{nameof(GenerateChangeAlertsForDebtor)} for={string.Join("/", changed)}");

            await _changeAlertGenerator.Generate(userIdentityId, culture,
                                                 itemEntityId,
                                                 itemTransactionId,
                                                 debtor.NameId,
                                                 hasDebtorChanged: debtor.IsOverriddenDebtor,
                                                 hasDebtorReferenceChanged: debtor.HasReferenceNoChanged,
                                                 hasAddressChanged: debtor.HasAddressChanged,
                                                 hasAttentionChanged: debtor.HasAttentionNameChanged,
                                                 addressChangeReasonId: debtor.AddressChangeReasonId);
        }

        async Task GenerateChangeAlertsForDebtorCopiesTo(int userIdentityId, string culture, int itemEntityId, int itemTransactionId, DebtorCopiesTo copiesTo)
        {
            var changed = new List<string>(new[] { $"{copiesTo.DebtorNameId} cc {copiesTo.CopyToNameId}" });
            if (copiesTo.HasAddressChanged) changed.Add($"Address (reason={copiesTo.AddressChangeReasonId})");
            if (copiesTo.HasAttentionChanged) changed.Add("Attention");

            _logger.Trace($"{nameof(GenerateChangeAlertsForDebtor)} for={string.Join("/", changed)}");

            await _changeAlertGenerator.Generate(userIdentityId, culture,
                                                 itemEntityId,
                                                 itemTransactionId,
                                                 copiesTo.DebtorNameId,
                                                 copiesTo.CopyToNameId,
                                                 false,
                                                 hasAddressChanged: copiesTo.HasAddressChanged,
                                                 hasAttentionChanged: copiesTo.HasAttentionChanged,
                                                 addressChangeReasonId: copiesTo.AddressChangeReasonId);
        }

        static bool IsReminderRequired(DebtorData debtor)
        {
            if (debtor.IsOverriddenDebtor) return true;

            if (debtor.AddressChangeReasonId != null && (
                    debtor.HasAddressChanged || debtor.HasAttentionNameChanged || debtor.HasReferenceNoChanged))
            {
                return true;
            }

            return debtor.HasCopyToDataChanged && debtor.CopiesTos.Any(ct => ct.AddressChangeReasonId != null);
        }

        static bool IsReminderRequired(DebtorCopiesTo debtor)
        {
            if (debtor.AddressChangeReasonId == null) return false;

            return debtor.HasAddressChanged ||
                   debtor.HasAttentionChanged ||
                   debtor.IsCopyToNameChanged ||
                   debtor.IsDeletedCopyToName ||
                   debtor.IsNewCopyToName;
        }
    }
}
