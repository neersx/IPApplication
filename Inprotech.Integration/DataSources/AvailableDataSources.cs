using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Integration.DataSources
{
    public interface IAvailableDataSources
    {
        IEnumerable<DataSourceType> List();
    }

    public class AvailableDataSources : IAvailableDataSources
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;

        readonly Dictionary<ApplicationTask, DataSourceType> _taskToDataSourceMap = new Dictionary<ApplicationTask, DataSourceType>
        {
            {ApplicationTask.ScheduleUsptoTsdrDataDownload, DataSourceType.UsptoTsdr},
            {ApplicationTask.ScheduleUsptoPrivatePairDataDownload, DataSourceType.UsptoPrivatePair},
            {ApplicationTask.ScheduleEpoDataDownload, DataSourceType.Epo},
            {ApplicationTask.ScheduleIpOneDataDownload, DataSourceType.IpOneData},
            {ApplicationTask.ScheduleFileDataDownload, DataSourceType.File}
        };

        public AvailableDataSources(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider;
        }

        public IEnumerable<DataSourceType> List()
        {
            var keys = _taskToDataSourceMap.Keys.Cast<int>();

            return _taskSecurityProvider.ListAvailableTasks()
                                        .Where(at => keys.Contains(at.TaskId))
                                        .Select(at =>
                                                    _taskToDataSourceMap[(ApplicationTask) at.TaskId]
                                               );
        }
    }
}