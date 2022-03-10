using System;
using Dependable.Dispatcher;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Accounting.Time.Posting
{
    public class PostTime
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _clock;
        readonly IBackgroundProcessLogger<PostTime> _logger;

        public PostTime(IDbContext dbContext, Func<DateTime> clock, IBackgroundProcessLogger<PostTime> logger)
        {
            _logger = logger;
            _dbContext = dbContext;
            _clock = clock;
        }
        
        public void HandleException(ExceptionContext exception, PostTimeArgs args)
        {
            _logger.Exception(exception.Exception, exception.Exception.Message);
            var bgProcess = new BackgroundProcess
            {
                IdentityId = args.UserIdentityId,
                ProcessType = BackgroundProcessType.General.ToString(),
                ProcessSubType = BackgroundProcessSubType.TimePosting.ToString(),
                Status = (int) StatusType.Error,
                StatusDate = _clock(),
                StatusInfo = args.ErrorMessage
            };
            _dbContext.Set<BackgroundProcess>().Add(bgProcess);
            _dbContext.SaveChanges();
        }
    }
}