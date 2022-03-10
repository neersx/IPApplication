using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ExchangeIntegration
{
    public interface IGraphNotification
    {
        Task SendAsync(string message, BackgroundProcessSubType backgroundProcessSubType, int userId);

        Task<bool> DeleteAsync(int userId);
    }

    public class GraphNotification : IGraphNotification
    {
        readonly IBackgroundProcessMessageClient _messageClient;
        readonly IDbContext _dbContext;

        public GraphNotification(IBackgroundProcessMessageClient messageClient, IDbContext dbContext)
        {
            _messageClient = messageClient;
            _dbContext = dbContext;
        }

        public async Task SendAsync(string message, BackgroundProcessSubType backgroundProcessSubType, int userId)
        {
            var backgroundProcessMessage = new BackgroundProcessMessage
            {
                ProcessType = BackgroundProcessType.UserAdministration,
                StatusType = StatusType.Information,
                ProcessSubType = backgroundProcessSubType,
                IdentityId = userId,
                Message = message
            };

            await _messageClient.SendAsync(backgroundProcessMessage);
        }

        public Task<bool> DeleteAsync(int userId)
        {
            var processIds = _dbContext.Set<BackgroundProcess>()
                                       .Where(_ => _.IdentityId == userId
                                                    && (_.ProcessSubType == BackgroundProcessSubType.GraphIntegrationCheckStatus.ToString()
                                                            || _.ProcessSubType == BackgroundProcessSubType.GraphStatus.ToString()))
                                       .Select(_ => _.Id);

            return processIds.Any() ? Task.FromResult(_messageClient.DeleteBackgroundProcessMessages(processIds.ToArray())) : Task.FromResult(false);
        }
    }
}
