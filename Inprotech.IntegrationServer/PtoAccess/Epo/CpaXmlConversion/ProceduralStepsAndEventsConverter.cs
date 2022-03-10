using System;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public interface IProceduralStepsAndEventsConverter
    {
        void Convert(registerdocument registerdocument, CaseDetails caseDetails);
    }

    public class ProceduralStepsAndEventsConverter : IProceduralStepsAndEventsConverter
    {
        readonly IOpsProcedureOrEventsResolver _opsProcedureOrEventsResolver;

        public ProceduralStepsAndEventsConverter(IOpsProcedureOrEventsResolver opsProcedureOrEventsResolver)
        {
            _opsProcedureOrEventsResolver = opsProcedureOrEventsResolver;
        }

        public void Convert(registerdocument registerdocument, CaseDetails caseDetails)
        {
            if (registerdocument == null) throw new ArgumentNullException(nameof(registerdocument));
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));

            var allEvents = _opsProcedureOrEventsResolver.Resolve(registerdocument);

            foreach (var @event in allEvents)
            {
                var caseEvent = caseDetails.CreateEventDetails(@event.Type);
                caseEvent.EventDate = @event.Date.ToString("yyyy-MM-dd");
                caseEvent.EventText = @event.Comments;
                caseEvent.EventDescription = @event.FormattedDescription;
            }
        }
    }
}
