using System;
using AutoMapper;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.DocumentGeneration
{
    public interface IActivityRequestHistoryMapper
    {
        CaseActivityRequest CopyAsNewRequest(CaseActivityRequest ar, Action<CaseActivityRequest, CaseActivityRequest> afterCopy = null);

        CaseActivityHistory CopyAsHistory(CaseActivityRequest ar, Action<CaseActivityRequest, CaseActivityHistory> afterCopy = null);
    }

    public class ActivityRequestHistoryMapper : IActivityRequestHistoryMapper
    {
        readonly IMapper _mapper;

        public ActivityRequestHistoryMapper(IMapper mapper)
        {
            _mapper = mapper;
        }

        public CaseActivityRequest CopyAsNewRequest(CaseActivityRequest ar, Action<CaseActivityRequest, CaseActivityRequest> afterCopy = null)
        {
            return afterCopy == null
                ? _mapper.Map<CaseActivityRequest, CaseActivityRequest>(ar)
                : _mapper.Map<CaseActivityRequest, CaseActivityRequest>(ar, x => { x.AfterMap(afterCopy); });
        }

        public CaseActivityHistory CopyAsHistory(CaseActivityRequest ar, Action<CaseActivityRequest, CaseActivityHistory> afterCopy = null)
        {
            return afterCopy == null
                ? _mapper.Map<CaseActivityRequest, CaseActivityHistory>(ar)
                : _mapper.Map<CaseActivityRequest, CaseActivityHistory>(ar, x => { x.AfterMap(afterCopy); });
        }
    }
}