using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Cases.Maintenance.Updaters
{
    public class DesignElementsTopicUpdater : ITopicDataUpdater<Case>
    {
        readonly ITransactionRecordal _transactionRecordal;
        readonly ISiteConfiguration _siteConfiguration;
        readonly IComponentResolver _componentResolver;

        public DesignElementsTopicUpdater(ITransactionRecordal transactionRecordal, ISiteConfiguration siteConfiguration, IComponentResolver componentResolver)
        {
            _transactionRecordal = transactionRecordal;
            _siteConfiguration = siteConfiguration;
            _componentResolver = componentResolver;
        }
        public void UpdateData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var topic = topicData.ToObject<DesignElementSaveModel>();
            var designElements = @case.CaseDesignElements.ToList();
            var maxId = designElements.Any() ? designElements.Max(_ => _.Sequence) : -1;

            var reasonNo = _siteConfiguration.TransactionReason ? _siteConfiguration.ReasonInternalChange : null;
            _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, _componentResolver.Resolve(KnownComponents.Case));

            foreach (var e in topic.Rows.OrderBy(_ => _.Status == KnownModifyStatus.Delete))
            {
                var editedElement = designElements.SingleOrDefault(x => x.Sequence == e.Sequence);
                if (e.Status == KnownModifyStatus.Delete)
                {
                    if (editedElement != null)
                    {
                        @case.CaseDesignElements.Remove(editedElement);
                        foreach (var img in @case.CaseImages.Where(_ => _.FirmElementId == editedElement.FirmElementId))
                        {
                            img.FirmElementId = null;
                        }
                    }
                    continue;
                }

                if (editedElement == null)
                {
                    editedElement = new DesignElement(@case.Id, ++maxId);
                    @case.CaseDesignElements.Add(editedElement);
                }
                UpdateCaseImages(@case, e, editedElement.FirmElementId);

                editedElement.FirmElementId = e.FirmElementCaseRef;
                editedElement.ClientElementId = e.ClientElementCaseRef;
                editedElement.Description = e.ElementDescription;
                editedElement.IsRenew = e.Renew;
                editedElement.OfficialElementId = e.ElementOfficialNo;
                editedElement.RegistrationNo = e.RegistrationNo;
                editedElement.StopRenewDate = e.StopRenewDate;
                editedElement.Typeface = e.NoOfViews;
            }
        }

        void UpdateCaseImages(Case @case, DesignElementData e, string oldFirmElementId)
        {
            var maxImageSeq = @case.CaseImages.Any() ? @case.CaseImages.Max(_ => _.ImageSequence) : (short)0;
            foreach (var img in @case.CaseImages.Where(_ => _.FirmElementId == oldFirmElementId && (e.Images == null || e.Images.All(x => x.Key != _.ImageId))))
            {
                img.FirmElementId = null;
            }

            if (e.Images == null) return;

            foreach (var img in @case.CaseImages.Where(_ => e.Images.Any(x => x.Key == _.ImageId)))
            {
                img.FirmElementId = e.FirmElementCaseRef;
            }

            foreach (var img in e.Images.Where(x => @case.CaseImages.All(_ => _.ImageId != x.Key)))
            {
                var ci = new CaseImage(@case, img.Key, ++maxImageSeq, KnownImageTypes.Design) { FirmElementId = e.FirmElementCaseRef, CaseImageDescription = img.Description };
                @case.CaseImages.Add(ci);
            }
        }

        public void PostSaveData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
        }
    }
}
