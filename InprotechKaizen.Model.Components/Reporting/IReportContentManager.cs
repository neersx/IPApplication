using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;

namespace InprotechKaizen.Model.Components.Reporting
{
    public interface IReportContentManager
    {
        Task Save(int? contentId, byte[] fileContent, string contentType, string fileName);

        Task Save(int? contentId, string filePath, string contentType);

        Task TryPutInBackground(int identityId, int? contentId, BackgroundProcessType backgroundProcessType);

        public void LogException(Exception exception, int contentId, string friendlyMessage = null, BackgroundProcessType? backgroundProcessType = null);
    }
}