using Newtonsoft.Json.Linq;

namespace Inprotech.Infrastructure.Web
{
    public interface IJsonPreferenceManager
    {
        JObject Get(int userId, int settingId);
        void Set(int userId, int settingId, JObject value);
        void Reset(int userId, int settingId);
    }
}
