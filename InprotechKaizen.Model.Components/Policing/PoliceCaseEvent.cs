using System;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Policing
{
    public interface IQueuedPolicingRequest
    {
        void Enqueue(int? batchNumber, IPolicingEngine policingEngine);
    }

    public interface IQueuedCaseEventPolicingRequest
    {
        QueuedCaseEventPolicingRequest CaseEvent { get; }
    }

    public class PoliceCaseEvent : IQueuedPolicingRequest, IQueuedCaseEventPolicingRequest
    {
        readonly CaseEvent _caseEvent;
        readonly DataEntryTask _dataEntryTask;

        public PoliceCaseEvent(CaseEvent caseEvent, DataEntryTask dataEntryTask)
        {
            _caseEvent = caseEvent;
            _dataEntryTask = dataEntryTask;
        }

        public PoliceCaseEvent(CaseEvent caseEvent)
        {
            _caseEvent = caseEvent ?? throw new ArgumentNullException(nameof(caseEvent));
        }

        public void Enqueue(int? batchNumber, IPolicingEngine policingEngine)
        {
            if (policingEngine == null) throw new ArgumentNullException(nameof(policingEngine));

            policingEngine.PoliceEvent(_caseEvent,
                _dataEntryTask?.CriteriaId,
                batchNumber, null);
        }

        public QueuedCaseEventPolicingRequest CaseEvent => new QueuedCaseEventPolicingRequest(_caseEvent);
    }

    public class QueuedCaseEventPolicingRequest
    {
        public int CaseId { get; }

        public int EventId { get; }

        public short Cycle { get; }

        public QueuedCaseEventPolicingRequest(CaseEvent caseEvent)
        {
            if (caseEvent == null) throw new ArgumentNullException(nameof(caseEvent));

            CaseId = caseEvent.CaseId;

            EventId = caseEvent.EventNo;

            Cycle = caseEvent.Cycle;
        }
    }
}