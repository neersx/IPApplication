using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules.Extensions;

namespace Inprotech.Integration.Schedules
{
    public interface IScheduleDetails
    {
        IEnumerable<object> Get();
    }

    public class ScheduleDetails : IScheduleDetails
    {
        readonly IAvailableDataSources _availableDataSources;
        readonly IDataSourceSchedule _dataSourceSchedule;
        readonly IRepository _repository;

        public ScheduleDetails(IRepository repository, IAvailableDataSources availableDataSources, IDataSourceSchedule dataSourceSchedule)
        {
            _repository = repository;
            _availableDataSources = availableDataSources;
            _dataSourceSchedule = dataSourceSchedule;
        }

        public IEnumerable<dynamic> Get()
        {
            var availableDataSources = _availableDataSources.List();

            var schedules = _repository.Set<Schedule>()
                                       .WhereVisibleToUsers()
                                       .Where(s => availableDataSources.Contains(s.DataSourceType))
                                       .OrderBy(s => s.NextRun);

            return _dataSourceSchedule.View(schedules);
        }
    }
}