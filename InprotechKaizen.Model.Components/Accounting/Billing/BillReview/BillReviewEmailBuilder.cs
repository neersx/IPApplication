using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace InprotechKaizen.Model.Components.Accounting.Billing.BillReview
{

    public interface IBillReviewEmailBuilder
    {
        Task<IEnumerable<(DraftEmailProperties Email, BillGenerationRequest Request, int? FirstCaseIncluded)>> Build(int userIdentityId, string culture, string reviewerMailbox, params BillGenerationRequest[] requests);
    }

    public class BillReviewEmailBuilder : IBillReviewEmailBuilder
    {
        readonly IDebtorListCommands _debtors;
        readonly IEmailRecipientsProvider _emailAddressProvider;
        readonly IEmailSubjectBodyResolver _emailSubjectBodyResolver;
        readonly IFileSystem _fileSystem;
        readonly IFinalisedBillDetailsResolver _finalisedBillDetails;
        readonly ILogger<BillReviewEmailBuilder> _logger;

        public BillReviewEmailBuilder(ILogger<BillReviewEmailBuilder> logger,
                                      IFinalisedBillDetailsResolver finalisedBillDetails,
                                      IEmailRecipientsProvider emailAddressProvider,
                                      IEmailSubjectBodyResolver emailSubjectBodyResolver,
                                      IDebtorListCommands debtors,
                                      IFileSystem fileSystem)
        {
            _logger = logger;
            _finalisedBillDetails = finalisedBillDetails;
            _emailAddressProvider = emailAddressProvider;
            _emailSubjectBodyResolver = emailSubjectBodyResolver;
            _debtors = debtors;
            _fileSystem = fileSystem;
        }

        public async Task<IEnumerable<(DraftEmailProperties Email, BillGenerationRequest Request, int? FirstCaseIncluded)>> Build(int userIdentityId, string culture, string reviewerMailbox, params BillGenerationRequest[] requests)
        {
            if (reviewerMailbox == null) throw new ArgumentNullException(nameof(reviewerMailbox));

            var prepared = new List<(DraftEmailProperties Email, BillGenerationRequest Request, int? FirstCaseIncluded)>();

            foreach (var request in requests)
            {
                if (request.ItemTransactionId == null)
                {
                    _logger.Warning($"Unable to send {request.OpenItemNo} for review incoming request is missing a transaction number, skipped.");
                    continue;
                }

                if (string.IsNullOrWhiteSpace(request.ResultFilePath))
                {
                    _logger.Warning($"Unable to send {request.OpenItemNo} for review because the file path to the bill is not provided, skipped.");
                    continue;
                }

                var details = await _finalisedBillDetails.Resolve(request);

                var caseId = details.Cases.Keys.FirstOrDefault();

                var debtorCopies = (await _debtors.GetCopiesTo(userIdentityId, culture,
                                                               request.ItemEntityId, (int)request.ItemTransactionId,
                                                               details.DebtorId, caseId, details.IsRenewalDebtor))
                    .ToArray();

                var emailAddresses = await _emailAddressProvider.Provide(details.DebtorId, debtorCopies);

                var email = new DraftEmailProperties
                {
                    Mailbox = reviewerMailbox
                };

                PopulateEmailRecipients(email, emailAddresses, details.DebtorId, debtorCopies);

                PopulateEmailSubjectBody(email, details.DebtorId, details.Cases);

                IncludeBillAsEmailAttachment(email, request.ResultFilePath);

                prepared.Add((email, request, caseId));
            }

            return prepared;
        }

        void IncludeBillAsEmailAttachment(DraftEmailProperties email, string billPath)
        {
            var content = _fileSystem.ReadAllBytes(billPath);
            var attachment = new EmailAttachment
            {
                FileName = Path.GetFileName(billPath),
                Content = Convert.ToBase64String(content)
            };

            email.Attachments.Add(attachment);
        }

        void PopulateEmailSubjectBody(DraftEmailProperties email, int debtorId, Dictionary<int, string> cases)
        {
            if (!cases.Any())
            {
                var debtorOnlySubjectBody = _emailSubjectBodyResolver.ResolveForName(debtorId);

                email.Subject = debtorOnlySubjectBody.Subject;
                email.Body = debtorOnlySubjectBody.Body;
            }
            
            foreach (var @case in cases)
            {
                var caseSubjectBody = _emailSubjectBodyResolver.ResolveForCase(@case.Value);

                if (!string.IsNullOrWhiteSpace(caseSubjectBody.Subject))
                {
                    email.Subject += caseSubjectBody.Subject + Environment.NewLine;
                }

                if (!string.IsNullOrWhiteSpace(caseSubjectBody.Body))
                {
                    email.Body += caseSubjectBody.Body + Environment.NewLine;
                }
            }

            email.Subject = email.Subject?.TrimEnd(Environment.NewLine.ToCharArray());
            email.Body = email.Body?.TrimEnd(Environment.NewLine.ToCharArray());
        }

        static void PopulateEmailRecipients(DraftEmailProperties email, Dictionary<int, IEnumerable<string>> emailAddresses, int debtorId, DebtorCopiesTo[] debtorCopies)
        {
            email.Recipients.AddRange(emailAddresses.Get(debtorId));

            foreach (var debtorCopiesTo in debtorCopies)
            {
                if (debtorCopiesTo.ContactNameId == null)
                {
                    email.CcRecipients.AddRange(emailAddresses.Get(debtorCopiesTo.CopyToNameId));
                    continue;
                }

                var c = emailAddresses.Get((int)debtorCopiesTo.ContactNameId).ToArray();
                email.CcRecipients.AddRange(c.Any() ? c : emailAddresses.Get(debtorCopiesTo.CopyToNameId));
            }
        }
    }
}