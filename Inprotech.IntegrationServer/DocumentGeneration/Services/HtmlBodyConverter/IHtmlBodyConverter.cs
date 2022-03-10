
using System.Collections.Generic;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter
{
    public interface IHtmlBodyConverter
    {
        Task<(string Body, IEnumerable<EmailAttachment> Attachments)> Convert(string sourceDocumentPath);
    }
}