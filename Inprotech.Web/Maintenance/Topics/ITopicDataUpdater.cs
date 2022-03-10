using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Maintenance.Topics
{
    public interface ITopicDataUpdater<T>
    {
        void UpdateData(JObject topicData, MaintenanceSaveModel model, T parentRecord);

        void PostSaveData(JObject topicData, MaintenanceSaveModel model, T parentRecord);
    }
}
