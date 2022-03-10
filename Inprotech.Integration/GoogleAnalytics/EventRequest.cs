using System;
using System.Collections.Generic;
using Inprotech.Integration.GoogleAnalytics.Parameters;

namespace Inprotech.Integration.GoogleAnalytics
{
    public interface IGoogleAnalyticsRequest
    {
        List<Parameter> Parameters { get; set; }

        void ValidateRequestParams();
    }

    public class EventRequest : IGoogleAnalyticsRequest
    {
        public string HitType;
        public EventRequest()
        {
            Parameters = new List<Parameter>();
            HitType = HitTypes.Event;
            Parameters.Add(new HitType(HitTypes.Event));
        }
        public List<Parameter> Parameters { get; set; }

        public void ValidateRequestParams()
        {
            if (!Parameters.Exists(p => p is EventCategory))
            {
                throw new ApplicationException("EventCategory parameter is missing.");
            }

            if (!Parameters.Exists(p => p is EventAction))
            {
                throw new ApplicationException("EventAction parameter is missing.");
            }
        }
    }
}