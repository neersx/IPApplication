using System.Collections.Generic;
using InprotechKaizen.Model;

namespace Inprotech.IntegrationServer.DocumentGeneration
{
    public static class DocGenRequestExtensions
    {
        static readonly Dictionary<int, string> DocumentTypeToRequestTypeMap =
            new Dictionary<int, string>
            {
                {KnownDocumentTypes.PdfViaReportingServices, TypeOfRequest.CreatePdfReportingServices}
            };

        static readonly Dictionary<int, string> DeliveryTypeToRequestTypeMap =
            new Dictionary<int, string>
            {
                {KnownDeliveryTypes.SaveDraftEmail, TypeOfRequest.DeliverDraftEmail}
            };

        public static string RequestType(this DocGenRequest request)
        {
            if (request == null) return "unknown";

            if (DocumentTypeToRequestTypeMap.TryGetValue(request.DocumentType, out var value))
            {
                // priority of pdf creation is deliberate.
                return value;
            }

            if (request.DeliveryType != null && DeliveryTypeToRequestTypeMap.TryGetValue((int) request.DeliveryType, out value))
            {
                return value;
            }

            return null;
        }
    }
}