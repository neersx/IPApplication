using System;
using System.Linq;
using System.Text;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.DeliverAsDraftEmail
{
    public interface IDraftEmailValidator
    {
        bool EnsureValid(DraftEmailProperties draftEmailProperties);
    }

    public class DraftEmailValidator : IDraftEmailValidator
    {
        public bool EnsureValid(DraftEmailProperties draftEmailProperties)
        {
            var messageBuilder = new StringBuilder();

            if (string.IsNullOrWhiteSpace(draftEmailProperties.Mailbox))
            {
                messageBuilder.AppendLine("Mailbox must be specified. Mailbox Email Doc Item must be set up in Letter Maintenance.");
            }

            if (!draftEmailProperties.Recipients.Any() && !draftEmailProperties.CcRecipients.Any())
            {
                messageBuilder.AppendLine("No email address has been specified. Email addresses are derived from Case Names, determined from the Correspondence Type of the Letter.");
            }

            var message = messageBuilder.ToString();

            if (string.IsNullOrWhiteSpace(message))
            {
                return true;
            }

            throw new ApplicationException(message);
        }
    }
}