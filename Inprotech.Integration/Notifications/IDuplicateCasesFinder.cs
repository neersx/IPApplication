using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Integration.Notifications
{
    public interface IDuplicateCasesFinder
    {
        Task<IEnumerable<int>> FindFor (int forNotificationId);

        Task<bool> AreDuplicatesPresent(int forNotificationId);
    } 
}
