using System;
using System.Linq;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Integration.Schedules
{
    public interface IScheduleExecutions
    {
        IQueryable<ScheduleExecutionsModel> Get(int scheduleId, ScheduleExecutionStatus? status = null);
    }

    class ScheduleExecutions : IScheduleExecutions
    {
        readonly IRepository _repository;

        public ScheduleExecutions(IRepository repository)
        {
            _repository = repository;
        }

        public IQueryable<ScheduleExecutionsModel> Get(int scheduleId, ScheduleExecutionStatus? status)
        {
            var filtered =
                _repository.Set<ScheduleExecution>()
                           .Where(_ => _.ScheduleId == scheduleId || _.Schedule.ParentId == scheduleId);

            var indexListAvailable = _repository.Set<ScheduleExecutionArtifact>()
                                                .Where(_ => _.CaseId == null);

            if (status != null)
            {
                filtered = filtered.Where(_ => _.Status == status);
            }

            return from f in filtered
                   join sea in indexListAvailable on f.Id equals sea.ScheduleExecutionId into seal
                   from sea in seal.DefaultIfEmpty()
                   orderby f.Started descending
                   select new ScheduleExecutionsModel
                          {
                              Id = f.Id,
                              Source = f.Schedule.DataSourceType.ToString(),
                              Status = f.Status.ToString(),
                              Type = f.Schedule.Type.ToString(),
                              Started = f.Started,
                              Finished = f.Finished,
                              CasesProcessed = f.CasesProcessed,
                              CasesIncluded = f.CasesIncluded,
                              CorrelationId = f.CorrelationId,
                              IndexList = sea != null ? sea.Blob : null,
                              CancellationData = f.CancellationData,
                              DocumentsIncluded = f.DocumentsIncluded,
                              DocumentsProcessed = f.DocumentsProcessed
                          };
        }
    }

    public class ScheduleExecutionsModel
    {
        public long Id { get; set; }

        public string Status { get; set; }

        [JsonIgnore]
        public string Source { get; set; }

        public string Type { get; set; }

        public DateTime Started { get; set; }

        public DateTime? Finished { get; set; }

        public int? CasesProcessed { get; set; }

        public int? CasesIncluded { get; set; }

        public int? DocumentsIncluded { get; set; }

        public int? DocumentsProcessed { get; set; }

        public string CorrelationId { get; set; }

        [JsonIgnore]
        public byte[] IndexList { get; set; }

        public bool AllowsIndexRetrieval => this.IsIndexRetrievalAllowed();

        [JsonIgnore]
        public string CancellationData { get; set; }

        public CancellationInfo CancellationInfo => this.GetCancellationInfo();
    }

    public static class ScheduleExecutionsModelExtension
    {
        static readonly string[] ScheduleTypesAllowed = new[]
                                                        {
                                                            ScheduleType.Scheduled.ToString(),
                                                            ScheduleType.OnDemand.ToString()
                                                        };

        static readonly string[] SourceAllowed = new[]
                                                 {
                                                     DataSourceType.UsptoPrivatePair.ToString()
                                                 };

        public static bool IsIndexRetrievalAllowed(this ScheduleExecutionsModel model)
        {
            return model.IndexList != null &&
                   ScheduleTypesAllowed.Contains(model.Type) &&
                   SourceAllowed.Contains(model.Source);
        }

        public static CancellationInfo GetCancellationInfo(this ScheduleExecutionsModel model)
        {
            if (string.IsNullOrWhiteSpace(model.CancellationData))
                return null;

            return JsonConvert.DeserializeObject<CancellationInfo>(model.CancellationData);
        }
    }
}