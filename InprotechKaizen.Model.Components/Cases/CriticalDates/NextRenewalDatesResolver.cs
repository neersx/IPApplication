using System;
using System.Threading.Tasks;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface INextRenewalDatesResolver
    {
        Task<RenewalDates> Resolve(int caseId, int? criteriaNo);

        Task<RenewalDates> Resolve(int caseId);
    }
    
    public class RenewalDates
    {
        public DateTime? NextRenewalDate { get; set; }

        public DateTime? CpaRenewalDate { get; set; }

        public short? AgeOfCase { get; set; }
    }
}