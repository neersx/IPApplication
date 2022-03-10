using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    public interface IStatusSupport
    {
        IEnumerable<StopPayReason> StopPayReasons();
        StopPayReason StopPayReasonFor(string userCode);
        dynamic Permissions();
    }

    public class StatusSupport : IStatusSupport
    {
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public StatusSupport(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (taskSecurityProvider == null) throw new ArgumentNullException("taskSecurityProvider");

            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public IEnumerable<StopPayReason> StopPayReasons()
        {
            var stopPayReasons =
               _dbContext.Set<TableCode>().Where(_ => _.TableTypeId == (short)TableTypes.CpaStopPayReason68).Select(_ => new StopPayReason
               {
                   Id = _.Id,
                   Name = _.Name,
                   UserCode = _.UserCode
               });

            return stopPayReasons;
        }

        public StopPayReason StopPayReasonFor(string userCode)
        {
            if (string.IsNullOrEmpty(userCode))
                return new StopPayReason();

            var tableCode =
                _dbContext.Set<TableCode>()
                    .Single(tc => tc.TableTypeId == (short)TableTypes.CpaStopPayReason68 && tc.UserCode == userCode);

            return new StopPayReason
                   {
                       Id = tableCode.Id,
                       Name = tableCode.Name,
                       UserCode = tableCode.UserCode
                   };
        }

        public dynamic Permissions()
        {
            return new
                    {
                        CanUpdate = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Modify),
                        CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Delete),
                        CanCreate = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Create),
                        CanMaintainValidCombination=_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainValidCombinations)
                    };
        }
    }
}
