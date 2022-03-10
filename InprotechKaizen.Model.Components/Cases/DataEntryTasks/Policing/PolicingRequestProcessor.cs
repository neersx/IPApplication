using System;
using System.Linq;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks.Policing
{
    public interface IPolicingRequestProcessor
    {
        int? Process(DataEntryTask dataEntryTask, PolicingRequests[] policingRequests);
    }

    public class PolicingRequestProcessor : IPolicingRequestProcessor
    {
        readonly IPolicingEngine _policingEngine;
        readonly IBatchPolicingRequest _batchPolicingRequest;

        public PolicingRequestProcessor(IPolicingEngine policingEngine, IBatchPolicingRequest batchPolicingRequest)
        {
            if(policingEngine == null) throw new ArgumentNullException("policingEngine");
            if (batchPolicingRequest == null) throw new ArgumentNullException("batchPolicingRequest");
            _policingEngine = policingEngine;
            _batchPolicingRequest = batchPolicingRequest;
        }

        public int? Process(DataEntryTask dataEntryTask, PolicingRequests[] policingRequests)
        {
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(policingRequests == null) throw new ArgumentNullException("policingRequests");

            if(!policingRequests.Any())
                return null;

            int? batchNumberForImmediatePolicing = null;

            var otherPoliceImmediatelyConsiderations =
                dataEntryTask.ShouldPoliceImmediate ||
                policingRequests.Any(r => r.ShouldPoliceImmediately);

            if (_batchPolicingRequest.ShouldPoliceImmediately(
                otherPoliceImmediatelyConsiderations))
            {
                batchNumberForImmediatePolicing = _policingEngine.CreateBatch();
            }

            foreach(var pr in policingRequests.SelectMany(r => r.Requests))
                pr.Enqueue(batchNumberForImmediatePolicing, _policingEngine);

            return batchNumberForImmediatePolicing;
        }
    }
}