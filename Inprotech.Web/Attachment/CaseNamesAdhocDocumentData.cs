using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;

namespace Inprotech.Web.Attachment
{
    public interface ICaseNamesAdhocDocumentData
    {
        Task<AdhocDocumentDataModel> Resolve(int? caseId, int? nameId, int documentId, bool addAsAttachment);
    }

    public class AdhocDocumentDataModel
    {
        public string NetworkTemplatesPath { get; set; }
        public string LocalTemplatesPath { get; set; }
        public string DirectoryName { get; set; }
        public string FileName { get; set; }
    }

    internal class CaseNamesAdhocDocumentData : ICaseNamesAdhocDocumentData
    {
        readonly IDeliveryDestinationResolver _destinationResolver;
        readonly ISiteControlReader _siteControlReader;

        public CaseNamesAdhocDocumentData(ISiteControlReader siteControlReader, IDeliveryDestinationResolver destinationResolver)
        {
            _siteControlReader = siteControlReader;
            _destinationResolver = destinationResolver;
        }

        public async Task<AdhocDocumentDataModel> Resolve(int? caseId, int? nameId, int documentId, bool addAsAttachment)
        {
            var templateLocations = _siteControlReader.ReadMany<string>(SiteControls.InproDocNetworkTemplates, SiteControls.InproDocLocalTemplates);

            var folder = new DeliveryDestination();
            if (addAsAttachment)
            {
                folder = await _destinationResolver.ResolveForCaseNames(caseId, nameId, (short) documentId);
            }

            return new AdhocDocumentDataModel
            {
                NetworkTemplatesPath = templateLocations.ContainsKey(SiteControls.InproDocNetworkTemplates)
                    ? templateLocations[SiteControls.InproDocNetworkTemplates]
                    : null,
                LocalTemplatesPath = templateLocations.ContainsKey(SiteControls.InproDocLocalTemplates)
                    ? templateLocations[SiteControls.InproDocLocalTemplates]
                    : null,
                DirectoryName = folder.DirectoryName,
                FileName = folder.FileName
            };
        }
    }
}