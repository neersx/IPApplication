using System.Threading.Tasks;

namespace Inprotech.Infrastructure
{
    public interface IUserPreferenceManager
    {
        T GetPreference<T>(int userId, int setting);
        Task<T[]> GetPreferences<T>(int userId, int[] settingIds) where T : class, new();
        void SetPreference<T>(int userId, int settingId, T boolValue);
        void ResetUserPreferences(int userId, int[] settingIds);
    }
}