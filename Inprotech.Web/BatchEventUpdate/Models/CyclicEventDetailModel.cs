using System;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class CyclicEventDetailModel
    {
        public CyclicEventDetailModel(CaseEvent caseEvent)
        {
            if(caseEvent == null) throw new ArgumentNullException("caseEvent");

            Cycle = caseEvent.Cycle;
            DueDate = caseEvent.EventDueDate;
            EventDate = caseEvent.EventDate;
        }

        public int Cycle { get; set; }

        public DateTime? DueDate { get; set; }

        public DateTime? EventDate { get; set; }
    }
}