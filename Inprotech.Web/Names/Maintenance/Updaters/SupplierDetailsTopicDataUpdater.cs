using Inprotech.Web.Maintenance.Topics;
using Inprotech.Web.Names.Details;
using Inprotech.Web.Names.Maintenance.Models;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Names.Maintenance.Updaters
{
    public class SupplierDetailsTopicDataUpdater : ITopicDataUpdater<Name>
    {
        readonly ISupplierDetailsMaintenance _supplierDetailsMaintenance;
    
        public SupplierDetailsTopicDataUpdater(ISupplierDetailsMaintenance supplierDetailsMaintenance)
        {
            _supplierDetailsMaintenance = supplierDetailsMaintenance;
        }

        public void UpdateData(JObject topicData, MaintenanceSaveModel model, Name name)
        {
            var topic = topicData.ToObject<SupplierDetailsSaveModel>();
            _supplierDetailsMaintenance.SaveSupplierDetails(name.Id, topic);
        }
        
        public void PostSaveData(JObject topicData, MaintenanceSaveModel model, Name name)
        {
            var topic = topicData.ToObject<SupplierDetailsSaveModel>();
            if (topic.SendToName != topic.OldSendToName)
            {
                _supplierDetailsMaintenance.SaveAssociatedNameAndRecalculateDerivedAttention(name.Id, topic, true);
            }
        }
    }
}