using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Integration.Settings;
using System.Linq;
using System.Web.Http;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    [ViewInitialiser]
    public class NewScheduleViewController : ApiController
    {
        readonly IRepository _repository;
        readonly IAvailableDataSources _availableDataSources;
        readonly IDmsIntegrationSettings _settings;
        readonly IIndex<DataSourceType, IDataSourceSchedulePrerequisites> _prerequisites;

        public NewScheduleViewController(IRepository repository, IAvailableDataSources availableDataSources,
            IDmsIntegrationSettings settings, IIndex<DataSourceType, IDataSourceSchedulePrerequisites> prerequisites)
        {
            _repository = repository;
            _availableDataSources = availableDataSources;
            _settings = settings;
            _prerequisites = prerequisites;
        }

        [HttpGet]
        [Route("api/ptoaccess/newscheduleview")]
        public dynamic Get()
        {
            var availableDataSources = _availableDataSources.List().ToArray();

            return new
            {
                DataSources =
                    availableDataSources.Select(
                                                _ =>
                                                {
                                                    string unmet = null;
                                                    IDataSourceSchedulePrerequisites p;
                                                    if (_prerequisites.TryGetValue(_, out p))
                                                    {
                                                        p.Validate(out unmet);
                                                    }

                                                    return new
                                                    {
                                                        Id = _.ToString(),
                                                        DmsIntegrationEnabled = _settings.IsEnabledFor(_),
                                                        Error = unmet
                                                    };
                                                })
            };
        }
    }
}