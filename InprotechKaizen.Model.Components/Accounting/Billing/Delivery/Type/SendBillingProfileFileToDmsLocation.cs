using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Storage;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Type
{
    public class SendBillingProfileFileToDmsLocation : IBillDeliveryService
    {
        readonly ILogger<SendBillingProfileFileToDmsLocation> _logger;
        readonly ISiteControlReader _siteControlReader;
        readonly IBillXmlProfileResolver _billXmlProfileResolver;
        readonly IChunkedStreamWriter _streamWriter;

        string _docMgmtDirectory;
        string _billXmlProfile;
        bool _shouldOutputTextAsAnsi;

        bool _settingsResolved;

        const string DefaultBillXmlProfileProcedure = "xml_BillingProfile";
        const string RequiredSiteControlNotSet =
            "Both '{0}' and '{1}' Site Controls must be configured for Bill XML Profile files to be created.";

        public SendBillingProfileFileToDmsLocation(ILogger<SendBillingProfileFileToDmsLocation> logger,
                                                   ISiteControlReader siteControlReader,
                                                   IBillXmlProfileResolver billXmlProfileResolver,
                                                   IChunkedStreamWriter streamWriter)
        {
            _logger = logger;
            _siteControlReader = siteControlReader;
            _billXmlProfileResolver = billXmlProfileResolver;
            _streamWriter = streamWriter;
        }

        public async Task Deliver(int userIdentityId, string culture, Guid contextId, params BillGenerationRequest[] requests)
        {
            await ResolveSettings();

            _logger.SetContext(contextId);

            foreach (var request in requests)
            {
                if (!request.IsFinalisedBill) continue;

                var xmlString = await _billXmlProfileResolver.Resolve(_billXmlProfile, request);

                var billXmlProfile = _shouldOutputTextAsAnsi
                    ? Encoding.UTF8.GetBytes(xmlString)
                    : Encoding.Unicode.GetBytes(xmlString);

                var path = Path.Combine(_docMgmtDirectory, $"{request.OpenItemNo}.xml");

                using var ms = new MemoryStream(billXmlProfile);
                await _streamWriter.Write(path, ms);

                _logger.Trace($"Billing Xml Profile for '{request.OpenItemNo}' has been written to {path}, ANSI={_shouldOutputTextAsAnsi}");
            }
        }

        public async Task EnsureValidSettings()
        {
            await ResolveSettings();

            if (!string.IsNullOrWhiteSpace(_billXmlProfile) && !string.IsNullOrWhiteSpace(_docMgmtDirectory))
            {
                return;
            }

            throw new ApplicationException(string.Format(RequiredSiteControlNotSet, SiteControls.DocMgmtDirectory, SiteControls.BillXMLProfile));
        }

        Task ResolveSettings()
        {
            if (!_settingsResolved)
            {
                var dmsSettings = _siteControlReader.ReadMany<string>(SiteControls.BillXMLProfile, SiteControls.DocMgmtDirectory);

                _docMgmtDirectory = dmsSettings.Get(SiteControls.DocMgmtDirectory);
                _billXmlProfile = dmsSettings.Get(SiteControls.BillXMLProfile);

                if (string.IsNullOrWhiteSpace(_billXmlProfile))
                {
                    _billXmlProfile = DefaultBillXmlProfileProcedure;
                }

                _shouldOutputTextAsAnsi = _siteControlReader.Read<bool>(SiteControls.XMLTextOutputANSI);

                _settingsResolved = true;
            }

            return Task.CompletedTask;
        }
    }
}
