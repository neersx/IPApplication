using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.IO;
using System.Linq;
using Inprotech.Infrastructure.IO;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Schedules
{
    public interface IResolveScheduleExecutionRootFolder
    {
        string Resolve(Guid sessionGuid);
    }

    public class ScheduleExecutionRootResolver : IResolveScheduleExecutionRootFolder
    {
        readonly IRepository _repository;

        public ScheduleExecutionRootResolver(IRepository repository)
        {
            _repository = repository;
        }

        public string Resolve(Guid sessionGuid)
        {
            var dataSourceTypeAndScheduleName = _repository.Set<ScheduleExecution>()
                                                           .Include(se => se.Schedule)
                                                           .Where(se => se.SessionGuid == sessionGuid)
                                                           .Select(se => new {se.Schedule.DataSourceType, se.Schedule.Name})
                                                           .Single();

            var parts = new List<string>(GetDataSourceTypeRootParts(dataSourceTypeAndScheduleName.DataSourceType))
                        {
                            StorageHelpers.EnsureValid(dataSourceTypeAndScheduleName.Name),
                            sessionGuid.ToString()
                        };

            return Path.Combine(parts.ToArray());
        }

        IEnumerable<string> GetDataSourceTypeRootParts(DataSourceType dataSourceType)
        {
            switch (dataSourceType)
            {
                case DataSourceType.UsptoPrivatePair:
                    return new[] {"UsptoIntegration"};
                default:
                    return new[] {"PtoIntegration", dataSourceType.ToString()};
            }
        }
    }

    public class CachingScheduleExecutionRootResolver : IResolveScheduleExecutionRootFolder
    {
        readonly IDictionary<Guid, string> _cache = new Dictionary<Guid, string>();
        readonly IResolveScheduleExecutionRootFolder _innerResolver;

        public CachingScheduleExecutionRootResolver(IResolveScheduleExecutionRootFolder innerResolver)
        {
            _innerResolver = innerResolver;
        }

        public string Resolve(Guid sessionGuid)
        {
            if (_cache.TryGetValue(sessionGuid, out string result)) return result;

            result = _innerResolver.Resolve(sessionGuid);
            _cache.Add(sessionGuid, result);

            return result;
        }
    }
}