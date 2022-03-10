using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class ValueTime : IValueTime
    {
        readonly ISiteControlReader _siteControlReader;
        readonly IWipCosting _wipCosting;
        readonly ITimeSplitter _timeSplitter;
        readonly IMapper _mapper;

        public ValueTime( ISiteControlReader siteControlReader, IWipCosting wipCosting, ITimeSplitter timeSplitter, IMapper mapper)
        {
            _siteControlReader = siteControlReader;
            _wipCosting = wipCosting;
            _timeSplitter = timeSplitter;
            _mapper = mapper;
        }

        public async Task<TimeEntry> For(RecordableTime timeEntry, string culture, int? userId = null)
        {
            TimeEntry result;
            if (_siteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor))
            {
                var timeWithSplits = await _timeSplitter.SplitTime(culture, timeEntry, timeEntry.StaffId.Value);
                if (timeWithSplits.DebtorSplits.Any())
                {
                    result = _timeSplitter.AggregateSplitIntoTime(timeWithSplits);
                    result.EntryNo = timeEntry.EntryNo;
                    result.StaffId = timeEntry.StaffId.GetValueOrDefault();

                    return result;
                }   
            }

            var valuedTime = await _wipCosting.For(timeEntry, userId.GetValueOrDefault());
            result = _mapper.Map<TimeEntry>(valuedTime);
            result.EntryNo = timeEntry.EntryNo;
            result.StaffId = timeEntry.StaffId.GetValueOrDefault();

            return result;
        }
    }

    public interface IValueTime
    {
        Task<TimeEntry> For(RecordableTime timeEntry, string culture, int? userId = null);
    }
}