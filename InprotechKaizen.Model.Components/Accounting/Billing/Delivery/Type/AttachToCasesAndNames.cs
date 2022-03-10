using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Type
{
    public class AttachToCasesAndNames : IBillDeliveryService
    {
        readonly ICreateActivityAttachment _createActivityAttachment;
        readonly IDbContext _dbContext;
        readonly ILogger<AttachToCasesAndNames> _logger;
        readonly IFinalisedBillDetailsResolver _finalisedBillDetails;

        public AttachToCasesAndNames(IDbContext dbContext,
                                     ILogger<AttachToCasesAndNames> logger,
                                     IFinalisedBillDetailsResolver finalisedBillDetails,
                                     ICreateActivityAttachment createActivityAttachment)
        {
            _dbContext = dbContext;
            _logger = logger;
            _finalisedBillDetails = finalisedBillDetails;
            _createActivityAttachment = createActivityAttachment;
        }

        public async Task Deliver(int userIdentityId, string culture, Guid contextId, params BillGenerationRequest[] requests)
        {
            _logger.SetContext(contextId);

            var itemTypeDescriptions = await GetItemDescriptions(culture);

            foreach (var request in requests)
            {
                if (!request.IsFinalisedBill) continue;

                if (string.IsNullOrWhiteSpace(request.FileName)) continue;

                var details = await _finalisedBillDetails.Resolve(request);
                var attachmentSummary = itemTypeDescriptions[(short)details.ItemType];
                var attachmentName = $"{attachmentSummary} {request.OpenItemNo}";

                var debtorAttachment = await _createActivityAttachment.Exec(userIdentityId,
                                                                            null,
                                                                            details.DebtorId,
                                                                            KnownActivityTypes.DebitOrCreditNote,
                                                                            KnownActivityCategories.Billing,
                                                                            details.ItemDate,
                                                                            attachmentSummary,
                                                                            attachmentName,
                                                                            request.FileName,
                                                                            isPublic: true);

                _logger.Trace($"Created attachment link for '{request.OpenItemNo}' for debtor={details.DebtorId}, activityId={debtorAttachment.Id}, filename={request.FileName}");

                foreach (var @case in details.Cases)
                {
                    var caseAttachment = await _createActivityAttachment.Exec(userIdentityId,
                                                                              @case.Key,
                                                                              null,
                                                                              KnownActivityTypes.DebitOrCreditNote,
                                                                              KnownActivityCategories.Billing,
                                                                              details.ItemDate,
                                                                              attachmentSummary,
                                                                              attachmentName,
                                                                              request.FileName,
                                                                              isPublic: true);

                    _logger.Trace($"Created attachment link for '{request.OpenItemNo}' for caseId={@case}, activityId={caseAttachment.Id}, filename={request.FileName}");
                }
            }
        }

        public Task EnsureValidSettings()
        {
            return Task.CompletedTask;
        }

        async Task<Dictionary<short, string>> GetItemDescriptions(string culture)
        {
            return await (from d in _dbContext.Set<DebtorItemType>()
                          select new
                          {
                              ItemType = d.ItemTypeId,
                              Description = DbFuncs.GetTranslation(d.Description, null, d.DescriptionTId, culture)
                          }).ToDictionaryAsync(k => k.ItemType, v => v.Description);
        }
    }
}