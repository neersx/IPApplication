using System;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Models
{
    public interface IEvent
    {
        int? Id { get; set; }
        string EventCode { get; set; }
        DateTime? EventDate { get; set; }
        string EventDescription { get; set; }
    }
}