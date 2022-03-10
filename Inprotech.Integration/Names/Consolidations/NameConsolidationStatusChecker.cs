using System.Collections.Generic;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.Jobs;

namespace Inprotech.Integration.Names.Consolidations
{
    public interface INameConsolidationStatusChecker
    {
        NameConsolidationStatusDto GetStatus();
    }

    public class NameConsolidationStatusChecker : INameConsolidationStatusChecker
    {
        readonly IConfigureJob _configureJob;

        public NameConsolidationStatusChecker(IConfigureJob configureJob)
        {
            _configureJob = configureJob;
        }

        public NameConsolidationStatusDto GetStatus()
        {
            var jobStatus = _configureJob.GetJobStatus(nameof(NameConsolidationJob));
            
            var rawStatus = jobStatus.State?.ToObject<NameConsolidationStatus>() ?? new NameConsolidationStatus{ IsCompleted = true };

            var dto = new NameConsolidationStatusDto();
            
            dto.NamesConsolidated.AddRange(rawStatus.NamesConsolidated);
            dto.NamesCouldNotConsolidate.AddRange(rawStatus.Errors.Keys);
            dto.IsCompleted = rawStatus.IsCompleted;
            dto.NumberOfNamesToConsolidate = rawStatus.NumberOfNamesToConsolidate;
            
            return dto;
        }
    }

    public class NameConsolidationStatusDto
    {
        public NameConsolidationStatusDto()
        {
            NamesConsolidated = new HashSet<int>();
            NamesCouldNotConsolidate = new HashSet<int>();
        }

        public bool IsCompleted { get; set; }

        public int NumberOfNamesToConsolidate { get; set; }

        public HashSet<int> NamesConsolidated { get; set; }

        public HashSet<int> NamesCouldNotConsolidate { get; set; }
    }
}
